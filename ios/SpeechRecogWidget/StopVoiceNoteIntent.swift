import AppIntents
import SpeechRecogShared

/// Runs in the widget extension. The recording itself lives in the app process;
/// this intent only signals it. The Action Button shortcut stops the note directly.
struct StopVoiceNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Voice Note"
    static var description = IntentDescription("Stops the SpeechRecog voice note that is recording.")
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult {
        RecordingSignal.postStop()
        return .result()
    }
}
