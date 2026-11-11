import AppIntents
import Foundation

/// Action Button shortcut. One press starts a note; the next press stops it,
/// transcribes it, and summarizes it.
///
/// `AudioRecordingIntent` lets the system run this without opening the app, but
/// only while a Live Activity is up — otherwise iOS stops the microphone.
/// A cold launch often cannot activate the audio session in the background, so
/// the intent then continues in the foreground and starts recording on screen.
struct ToggleVoiceNoteIntent: AudioRecordingIntent {
    static var title: LocalizedStringResource = "Voice Note"
    static var description = IntentDescription(
        "Starts a SpeechRecog voice note, or stops it and saves a transcript and summary."
    )
    static var openAppWhenRun: Bool = false
    static var supportedModes: IntentModes = [.background, .foreground(.dynamic)]

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let message = try await run()
        return .result(dialog: Self.dialog(message))
    }

    private func run() async throws -> String {
        let controller = VoiceNoteController.shared
        if await controller.isRecording {
            return await controller.stopAndProcess()
        }
        if await controller.isBusy {
            return "Still finishing the previous note."
        }

        if systemContext.currentMode == .background {
            switch await controller.beginRecording(allowMissingLiveActivity: false) {
            case .started:
                return "Recording a voice note. Press the Action Button again to stop."
            case .failed(let message):
                return message
            case .needsForeground(let reason):
                guard systemContext.currentMode.canContinueInForeground else { return reason }
                do {
                    try await continueInForeground(alwaysConfirm: false)
                } catch {
                    return reason
                }
                return Self.message(for: await controller.beginRecording(allowMissingLiveActivity: true), opened: true)
            }
        }

        return Self.message(for: await controller.beginRecording(allowMissingLiveActivity: true), opened: false)
    }

    private static func message(for attempt: VoiceNoteController.BeginResult, opened: Bool) -> String {
        switch attempt {
        case .started:
            return opened
                ? "Recording. Press the Action Button again to stop."
                : "Recording a voice note. Press the Action Button again to stop."
        case .failed(let message), .needsForeground(let message):
            return message
        }
    }

    private static func dialog(_ text: String) -> IntentDialog {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = trimmed.isEmpty ? "Saved the voice note." : trimmed
        guard value.count > 180 else { return IntentDialog(stringLiteral: value) }
        let end = value.index(value.startIndex, offsetBy: 180)
        return IntentDialog(stringLiteral: String(value[..<end]) + "…")
    }
}
