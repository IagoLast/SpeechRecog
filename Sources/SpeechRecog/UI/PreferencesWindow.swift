import AppKit
import SwiftUI

enum PreferencesWindow {
    @MainActor
    static func make(settings: Settings) -> NSWindow {
        let view = PreferencesView(settings: settings)
        let host = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: host)
        window.title = "SpeechRecog · Preferencias"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 460, height: 280))
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }
}

private struct PreferencesView: View {
    @ObservedObject var settings: Settings

    var body: some View {
        Form {
            Section("Transcripción") {
                Picker("Motor", selection: $settings.transcriptionBackend) {
                    ForEach(TranscriptionBackend.allCases) { backend in
                        Text(backend.displayName).tag(backend)
                    }
                }

                if settings.transcriptionBackend == .whisperKit {
                    Picker("Modelo Whisper", selection: $settings.whisperModel) {
                        ForEach(WhisperModel.allCases) { model in
                            Text(model.displayName).tag(model.rawValue)
                        }
                    }
                }

                TextField(
                    "Idioma (BCP-47, vacío = auto)",
                    text: Binding(
                        get: { settings.language ?? "" },
                        set: { settings.language = $0.isEmpty ? nil : $0 }
                    )
                )
            }

            Section {
                Text("Las grabaciones (.m4a) y subtítulos (.srt) se guardan en ~/Documents/SpeechRecog.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 460)
    }
}
