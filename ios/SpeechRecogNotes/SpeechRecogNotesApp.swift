import SwiftUI

@main
struct SpeechRecogNotesApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(VoiceNoteController.shared)
                .environment(AppSettings.shared)
        }
    }
}
