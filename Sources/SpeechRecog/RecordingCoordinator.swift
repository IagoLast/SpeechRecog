import Foundation
import Combine
import AppKit

@MainActor
final class RecordingCoordinator: ObservableObject {
    enum State: Equatable {
        case idle
        case recording
        case transcribing(progress: Double)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var audioLevel: Float = 0

    let settings = Settings()
    private(set) var store: RecordingsStore

    private var capture: SystemAudioCapture?
    private var micCapture: MicrophoneCapture?
    private var currentRecording: Recording?
    private var folderObserver: AnyCancellable?

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
        case .transcribing:
            break
        }
    }

    private func start() async {
        do {
            let recording = try store.makeNewRecording()

            let mic: MicrophoneCapture? = settings.includeMicrophone ? MicrophoneCapture() : nil

            let capture = SystemAudioCapture(outputURL: recording.audioURL, micCapture: mic)
            capture.onLevel = { [weak self] level in
                Task { @MainActor in
                    self?.audioLevel = level
                }
            }
            try capture.start()

            self.micCapture = mic
            self.capture = capture
            self.currentRecording = recording
            state = .recording
        } catch {
            NSLog("[SpeechRecog] start error: \(error)")
            presentError(error)
        }
    }

    private func stop() async {
        guard let capture, let recording = currentRecording else { return }
        do {
            try capture.stop()
        } catch {
            NSLog("[SpeechRecog] stop error: \(error)")
        }
        self.capture = nil
        self.micCapture?.stop()
        self.micCapture = nil
        self.currentRecording = nil
        self.audioLevel = 0

        state = .transcribing(progress: 0)
        do {
            let engine = try TranscriptionEngineFactory.make(settings: settings)
            let result = try await engine.transcribe(audioURL: recording.audioURL) { [weak self] progress in
                Task { @MainActor in
                    self?.state = .transcribing(progress: progress)
                }
            }
            try SRTWriter.write(segments: result.segments, to: recording.subtitleURL)
            NSLog("[SpeechRecog] transcript saved at \(recording.subtitleURL.path)")
        } catch {
            NSLog("[SpeechRecog] transcription error: \(error)")
            presentError(error)
        }
        state = .idle
    }

    func retranscribe(recording: Recording) async {
        guard case .idle = state else { return }
        state = .transcribing(progress: 0)
        do {
            let engine = try TranscriptionEngineFactory.make(settings: settings)
            let result = try await engine.transcribe(audioURL: recording.audioURL) { [weak self] progress in
                Task { @MainActor in
                    self?.state = .transcribing(progress: progress)
                }
            }
            try SRTWriter.write(segments: result.segments, to: recording.subtitleURL)
            NSLog("[SpeechRecog] re-transcript saved at \(recording.subtitleURL.path)")
        } catch {
            NSLog("[SpeechRecog] retranscription error: \(error)")
            presentError(error)
        }
        state = .idle
    }

    private func presentError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "SpeechRecog"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }
}
