import Foundation
import Combine
import AppKit

@MainActor
final class RecordingCoordinator: ObservableObject {
    enum State: Equatable {
        case idle
        case starting
        case recording
        case transcribing(progress: Double)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var audioLevel: Float = 0

    let settings = Settings()
    private(set) var store: RecordingsStore

    private var capture: SystemAudioCapture?
    private var currentRecording: Recording?
    private var folderObserver: AnyCancellable?
    private var transcriptionID: UUID?

    var recordingsFolder: URL { store.folder }

    init() {
        self.store = RecordingsStore(folder: settings.recordingsFolder)
        folderObserver = settings.$recordingsFolder.dropFirst().sink { [weak self] newFolder in
            self?.store = RecordingsStore(folder: newFolder)
        }
    }

    func toggleRecording() async {
        switch state {
        case .idle:
            await start()
        case .recording:
            await stop()
        case .starting, .transcribing:
            break
        }
    }

    private func start() async {
        state = .starting
        do {
            var mic: MicrophoneCapture?
            if settings.includeMicrophone {
                if await MicrophoneCapture.requestAccess() {
                    mic = MicrophoneCapture()
                } else {
                    NSLog("[SpeechRecog] Microphone access denied; recording system audio only")
                }
            }

            let recording = try store.makeNewRecording()

            let capture = SystemAudioCapture(outputURL: recording.audioURL, micCapture: mic)
            capture.onLevel = { [weak self] level in
                Task { @MainActor in
                    guard self?.state == .recording else { return }
                    self?.audioLevel = level
                }
            }
            try capture.start()

            self.capture = capture
            self.currentRecording = recording
            state = .recording
        } catch {
            state = .idle
            NSLog("[SpeechRecog] start error: \(error)")
            presentError(error)
        }
    }

    private func stop() async {
        guard let capture, let recording = currentRecording else { return }
        self.capture = nil
        currentRecording = nil
        audioLevel = 0
        do {
            try capture.stop()
        } catch {
            NSLog("[SpeechRecog] stop error: \(error)")
            state = .idle
            presentError(error)
            return
        }
        await transcribe(recording)
    }

    func retranscribe(recording: Recording) async {
        guard case .idle = state else { return }
        await transcribe(recording)
    }

    private func transcribe(_ recording: Recording) async {
        let id = UUID()
        transcriptionID = id
        state = .transcribing(progress: 0)
        defer {
            transcriptionID = nil
            state = .idle
        }
        do {
            let engine = TranscriptionEngineFactory.make(settings: settings)
            let result = try await engine.transcribe(audioURL: recording.audioURL) { [weak self] progress in
                Task { @MainActor in
                    guard let self, self.transcriptionID == id, progress.isFinite else { return }
                    self.state = .transcribing(progress: min(1, max(0, progress)))
                }
            }
            try SRTWriter.write(segments: result.segments, to: recording.subtitleURL)
            NSLog("[SpeechRecog] transcript saved at \(recording.subtitleURL.path)")
        } catch {
            NSLog("[SpeechRecog] transcription error: \(error)")
            presentError(error)
        }
    }

    func shutdown() {
        transcriptionID = nil
        do {
            try capture?.stop()
        } catch {
            NSLog("[SpeechRecog] shutdown error: \(error)")
        }
        capture = nil
    }

    private func presentError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "SpeechRecog"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }
}
