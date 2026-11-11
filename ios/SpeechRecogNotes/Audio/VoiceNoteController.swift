import ActivityKit
import AVFoundation
import Foundation
import Observation
import os
import SpeechRecogShared
import UIKit

@MainActor
@Observable
final class VoiceNoteController {
    static let shared = VoiceNoteController()

    enum Phase: Equatable {
        case idle
        case recording(startedAt: Date)
        case transcribing
        case summarizing
    }

    enum BeginResult: Equatable {
        case started
        case needsForeground(String)
        case failed(String)
    }

    private(set) var phase: Phase = .idle
    private(set) var notes: [VoiceNote] = []
    var lastError: String?

    var isRecording: Bool {
        if case .recording = phase { return true }
        return false
    }

    var isBusy: Bool {
        switch phase {
        case .transcribing, .summarizing: return true
        case .idle, .recording: return false
        }
    }

    var showsActivityBar: Bool { isRecording || isBusy }

    @ObservationIgnored private let store: NotesStore
    @ObservationIgnored private var recorder: AVAudioRecorder?
    @ObservationIgnored private var activity: Activity<RecordingActivityAttributes>?
    @ObservationIgnored private var activeURL: URL?
    @ObservationIgnored private var activeNoteID: UUID?
    @ObservationIgnored private var stopTask: Task<String, Never>?
    @ObservationIgnored private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    @ObservationIgnored private var interruptionToken: NSObjectProtocol?
    @ObservationIgnored private var stopToken: RecordingSignalToken?
    @ObservationIgnored private var didLoad = false
    @ObservationIgnored private var processingFiles = Set<String>()
    @ObservationIgnored private let log = Logger(subsystem: "es.speechrecog.notes", category: "notes")

    private init() {
        if let opened = try? NotesStore.make() {
            store = opened
        } else if let fallback = try? NotesStore(
            directory: FileManager.default.temporaryDirectory
                .appendingPathComponent("SpeechRecogNotes", isDirectory: true)
        ) {
            store = fallback
            lastError = "Couldn't open the notes folder. Notes will use temporary storage."
        } else {
            store = (try? NotesStore(directory: FileManager.default.temporaryDirectory))!
            lastError = "Couldn't open the notes folder."
        }
        installObservers()
    }

    func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true
        notes = store.load()
        Task { await self.recoverAndSweep() }
    }

    func audioURL(for note: VoiceNote) -> URL {
        store.audioURL(named: note.audioFilename)
    }

    func preparePermissions() {
        Task {
            if AVAudioApplication.shared.recordPermission == .undetermined {
                _ = await AVAudioApplication.requestRecordPermission()
            }
            if SFSpeechRecognizer.authorizationStatus() == .notDetermined {
                _ = try? await NoteTranscriber.requestAuthorization()
            }
        }
    }

    /// In-app microphone button. Already in the foreground, so a missing Live
    /// Activity must not block the recording.
    func toggleFromUI() async {
        if isRecording {
            _ = await stopAndProcess()
            return
        }
        guard !isBusy else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let result = await beginRecording(allowMissingLiveActivity: true)
        publish(result)
    }

    func beginRecording(allowMissingLiveActivity: Bool) async -> BeginResult {
        if isRecording { return .started }
        if isBusy { return .failed("Still finishing the previous note.") }

        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            break
        case .denied:
            return .failed(NoteError.microphoneDenied.localizedDescription)
        case .undetermined:
            if !allowMissingLiveActivity {
                return .needsForeground("Open SpeechRecog to allow the microphone. Recording starts once you do.")
            }
            let granted = await AVAudioApplication.requestRecordPermission()
            guard granted else { return .failed(NoteError.microphoneDenied.localizedDescription) }
        @unknown default:
            return .needsForeground("SpeechRecog needs microphone access.")
        }

        do {
            try activateSession()
        } catch {
            log.error("Audio session failed: \(error.localizedDescription, privacy: .public)")
            if allowMissingLiveActivity {
                return .failed("Couldn't start the microphone. \(error.localizedDescription)")
            }
            return .needsForeground("SpeechRecog needs to open to start the microphone.")
        }

        let noteID = UUID()
        let startedAt = Date()
        let url = store.newAudioURL()
        activeNoteID = noteID
        activeURL = url
        // Set this before the Live Activity so a launch-time sweep cannot end it.
        phase = .recording(startedAt: startedAt)

        do {
            try await startLiveActivity(noteID: noteID, startedAt: startedAt)
        } catch {
            log.error("Live Activity failed: \(error.localizedDescription, privacy: .public)")
            if !allowMissingLiveActivity {
                phase = .idle
                clearActiveFiles()
                deactivateSession()
                return .needsForeground("SpeechRecog will open so the recording stays on screen. iOS stops a background recording that has no Live Activity.")
            }
        }

        guard activeNoteID == noteID, isRecording else {
            clearActiveFiles()
            deactivateSession()
            return .failed("Recording was cancelled.")
        }

        do {
            try startRecorder(url: url)
        } catch {
            phase = .idle
            await endActivity(dismissal: .immediate, detail: nil, startedAt: startedAt)
            clearActiveFiles()
            deactivateSession()
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return .failed(message)
        }

        log.info("Recording started")
        return .started
    }

    func stopAndProcess() async -> String {
        if let stopTask { return await stopTask.value }
        let task = Task { @MainActor in
            await self.performStop()
        }
        stopTask = task
        let result = await task.value
        stopTask = nil
        return result
    }

    func reprocess(noteID: UUID) async {
        guard !isRecording, !isBusy else { return }
        guard let existing = notes.first(where: { $0.id == noteID }) else { return }
        let url = store.audioURL(named: existing.audioFilename)
        guard FileManager.default.fileExists(atPath: url.path) else {
            lastError = "The recording file is missing."
            return
        }
        holdBackgroundTime()
        defer { endBackgroundTime() }
        let text = await transcribeAndSummarize(url: url, startedAt: existing.createdAt, announceOnLockScreen: false)
        var updated = existing
        updated.transcript = text.transcript
        updated.summary = text.summary
        updated.actionItems = text.actionItems
        updated.summarizer = text.summarizer
        if updated.duration == 0 { updated.duration = text.duration }
        upsert(updated)
        phase = .idle
    }

    func delete(noteID: UUID) {
        guard let note = notes.first(where: { $0.id == noteID }) else { return }
        notes.removeAll { $0.id == noteID }
        store.removeAudio(named: note.audioFilename)
        persist()
    }

    private func performStop() async -> String {
        guard case .recording(let startedAt) = phase else { return "Not recording." }
        holdBackgroundTime()
        defer { endBackgroundTime() }

        let url = activeURL
        let noteID = activeNoteID ?? UUID()
        let hadRecorder = recorder != nil
        let duration = recorder?.currentTime ?? 0
        recorder?.stop()
        recorder = nil
        deactivateSession()
        log.info("Recording stopped")

        guard hadRecorder else {
            phase = .idle
            clearActive()
            await endActivity(dismissal: .immediate, detail: nil, startedAt: startedAt)
            return "Recording didn't start."
        }

        phase = .transcribing

        if let url {
            processingFiles.insert(url.lastPathComponent)
            upsert(VoiceNote(
                id: noteID,
                createdAt: startedAt,
                duration: duration,
                transcript: "",
                summary: "Transcribing…",
                actionItems: [],
                audioFilename: url.lastPathComponent,
                summarizer: "none"
            ))
        }
        defer { if let url { processingFiles.remove(url.lastPathComponent) } }

        let text = await transcribeAndSummarize(url: url, startedAt: startedAt, announceOnLockScreen: true)
        if let url {
            let note = VoiceNote(
                id: noteID,
                createdAt: startedAt,
                duration: duration > 0 ? duration : text.duration,
                transcript: text.transcript,
                summary: text.summary,
                actionItems: text.actionItems,
                audioFilename: url.lastPathComponent,
                summarizer: text.summarizer
            )
            upsert(note)
        }
        clearActive()
        phase = .idle
        await endActivity(dismissal: .after(Date().addingTimeInterval(8)), detail: text.summary, startedAt: startedAt)
        return text.summary.isEmpty ? "Saved the voice note." : text.summary
    }

    private struct ProcessedText {
        var transcript: String
        var summary: String
        var actionItems: [String]
        var summarizer: String
        var duration: TimeInterval
    }

    private func transcribeAndSummarize(url: URL?, startedAt: Date, announceOnLockScreen: Bool) async -> ProcessedText {
        phase = .transcribing
        if announceOnLockScreen {
            await updateActivity(phase: .transcribing, startedAt: startedAt, detail: "Transcribing")
        }

        var transcript = ""
        var failure: String?
        var fileDuration: TimeInterval = 0
        if let url {
            if let assetDuration = try? await AVURLAsset(url: url).load(.duration).seconds, assetDuration.isFinite {
                fileDuration = assetDuration
            }
            do {
                transcript = try await NoteTranscriber(languageCode: AppSettings.shared.languageCode)
                    .transcribe(audioURL: url)
            } catch {
                failure = error.localizedDescription
                log.error("Transcription failed: \(error.localizedDescription, privacy: .public)")
            }
        }

        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return ProcessedText(
                transcript: "",
                summary: failure ?? "No speech detected.",
                actionItems: [],
                summarizer: "none",
                duration: fileDuration
            )
        }

        phase = .summarizing
        if announceOnLockScreen {
            await updateActivity(phase: .summarizing, startedAt: startedAt, detail: "Summarizing")
        }
        let summarized = await summarize(trimmed)
        return ProcessedText(
            transcript: trimmed,
            summary: summarized.summary,
            actionItems: summarized.actionItems,
            summarizer: summarized.name,
            duration: fileDuration
        )
    }

    private func summarize(_ transcript: String) async -> (summary: String, actionItems: [String], name: String) {
        let primary = SummarizerFactory.make()
        do {
            let result = try await primary.summarize(transcript: transcript)
            return (cleanSummary(result.summary), cleanItems(result.actionItems), primary.name)
        } catch {
            log.error("Summarizer \(primary.name, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
            let fallback = ExtractiveSummarizer()
            let result = (try? await fallback.summarize(transcript: transcript))
                ?? NoteSummary(summary: ExtractiveSummarizer.summary(from: transcript), actionItems: [])
            return (cleanSummary(result.summary), cleanItems(result.actionItems), fallback.name)
        }
    }

    private func cleanSummary(_ summary: String) -> String {
        let trimmed = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "No summary." : trimmed
    }

    private func cleanItems(_ items: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for item in items {
            let trimmed = item.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            guard seen.insert(trimmed.lowercased()).inserted else { continue }
            result.append(trimmed)
            if result.count == 12 { break }
        }
        return result
    }

    private func recoverAndSweep() async {
        if !isRecording && !isBusy {
            for activity in Activity<RecordingActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        guard !isRecording, !isBusy else { return }
        let known = Set(notes.map(\.audioFilename))
        let activeName = activeURL?.lastPathComponent
        for url in store.unreferencedAudioFiles(excluding: known) {
            if url.lastPathComponent == activeName || processingFiles.contains(url.lastPathComponent) { continue }
            guard !isRecording, !isBusy else { return }
            let created = (try? url.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date()
            let placeholder = VoiceNote(
                id: UUID(),
                createdAt: created,
                duration: 0,
                transcript: "",
                summary: "Transcribing…",
                actionItems: [],
                audioFilename: url.lastPathComponent,
                summarizer: "none"
            )
            upsert(placeholder)
            let text = await transcribeAndSummarize(url: url, startedAt: created, announceOnLockScreen: false)
            var saved = placeholder
            saved.duration = text.duration
            saved.transcript = text.transcript
            saved.summary = text.summary
            saved.actionItems = text.actionItems
            saved.summarizer = text.summarizer
            upsert(saved)
            phase = .idle
        }

        let interrupted = notes.filter {
            $0.transcript.isEmpty && $0.summary == "Transcribing…" && !processingFiles.contains($0.audioFilename)
        }
        for note in interrupted {
            guard !isRecording, !isBusy else { return }
            let url = store.audioURL(named: note.audioFilename)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            processingFiles.insert(note.audioFilename)
            let text = await transcribeAndSummarize(url: url, startedAt: note.createdAt, announceOnLockScreen: false)
            processingFiles.remove(note.audioFilename)
            var saved = note
            saved.duration = note.duration > 0 ? note.duration : text.duration
            saved.transcript = text.transcript
            saved.summary = text.summary
            saved.actionItems = text.actionItems
            saved.summarizer = text.summarizer
            upsert(saved)
            phase = .idle
        }
    }

    private func publish(_ result: BeginResult) {
        switch result {
        case .started:
            break
        case .failed(let message), .needsForeground(let message):
            lastError = message
        }
    }

    private func upsert(_ note: VoiceNote) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
        } else {
            notes.insert(note, at: 0)
        }
        notes.sort { $0.createdAt > $1.createdAt }
        persist()
    }

    private func persist() {
        do {
            try store.save(notes)
        } catch {
            lastError = "Couldn't save notes. \(error.localizedDescription)"
        }
    }

    private func activateSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try session.setActive(true)
    }

    private func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func startRecorder(url: URL) throws {
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 64_000
        ]
        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.prepareToRecord()
        guard recorder.record() else {
            throw NoteError.recorderFailed("The microphone didn't start.")
        }
        self.recorder = recorder
    }

    private func startLiveActivity(noteID: UUID, startedAt: Date) async throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw NoteError.recorderFailed("Live Activities are turned off for SpeechRecog.")
        }
        for existing in Activity<RecordingActivityAttributes>.activities {
            await existing.end(nil, dismissalPolicy: .immediate)
        }
        let state = RecordingActivityAttributes.ContentState(phase: .recording, startedAt: startedAt, detail: "Recording")
        activity = try Activity.request(
            attributes: RecordingActivityAttributes(noteID: noteID.uuidString),
            content: ActivityContent(state: state, staleDate: nil),
            pushType: nil
        )
    }

    private func updateActivity(phase: RecordingActivityAttributes.Phase, startedAt: Date, detail: String) async {
        let state = RecordingActivityAttributes.ContentState(
            phase: phase,
            startedAt: startedAt,
            detail: Self.lockScreenDetail(detail)
        )
        await activity?.update(ActivityContent(state: state, staleDate: nil))
    }

    private func endActivity(dismissal: ActivityUIDismissalPolicy, detail: String?, startedAt: Date) async {
        guard let activity else { return }
        let state = RecordingActivityAttributes.ContentState(
            phase: .done,
            startedAt: startedAt,
            detail: Self.lockScreenDetail(detail ?? "Saved")
        )
        await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: dismissal)
        self.activity = nil
    }

    private static func lockScreenDetail(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 140 else { return trimmed }
        let end = trimmed.index(trimmed.startIndex, offsetBy: 140)
        return trimmed[..<end].trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }

    private func clearActive() {
        activeURL = nil
        activeNoteID = nil
    }

    private func clearActiveFiles() {
        if let activeURL, notes.contains(where: { $0.audioFilename == activeURL.lastPathComponent }) == false {
            try? FileManager.default.removeItem(at: activeURL)
        }
        clearActive()
    }

    private func holdBackgroundTime() {
        guard backgroundTask == .invalid else { return }
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "SpeechRecogProcess") { [weak self] in
            Task { @MainActor in
                self?.endBackgroundTime()
            }
        }
    }

    private func endBackgroundTime() {
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }

    private func installObservers() {
        interruptionToken = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            guard let raw, AVAudioSession.InterruptionType(rawValue: raw) == .began else { return }
            Task { @MainActor in
                guard let self, self.isRecording else { return }
                _ = await self.stopAndProcess()
            }
        }
        stopToken = RecordingSignal.addStopObserver {
            Task { @MainActor in
                guard VoiceNoteController.shared.isRecording else { return }
                _ = await VoiceNoteController.shared.stopAndProcess()
            }
        }
    }
}
