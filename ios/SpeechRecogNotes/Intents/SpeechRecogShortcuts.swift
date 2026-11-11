import AppIntents

struct SpeechRecogShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .red

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ToggleVoiceNoteIntent(),
            phrases: [
                "Take a voice note with \(.applicationName)",
                "Start a note in \(.applicationName)",
                "Toggle voice note in \(.applicationName)"
            ],
            shortTitle: "Voice Note",
            systemImageName: "mic.fill"
        )
    }
}
