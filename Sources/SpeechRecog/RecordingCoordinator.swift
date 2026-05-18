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

    let settings = Settings()
    let store = RecordingsStore()

    private var capture: SystemAudioCapture?
    private var currentRecording: Recording?

    var recordingsFolder: URL { store.folder }

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
            let capture = try SystemAudioCapture(outputURL: recording.audioURL)
            try capture.start()
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
        self.currentRecording = nil

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

    private func presentError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "SpeechRecog"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }
}
