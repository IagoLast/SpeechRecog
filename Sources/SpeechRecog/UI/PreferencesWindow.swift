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
        window.setContentSize(NSSize(width: 460, height: 400))
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }
}

private struct PreferencesView: View {
    @ObservedObject var settings: Settings

    var body: some View {
        Form {
            Section("Audio") {
                Toggle("Incluir micrófono", isOn: $settings.includeMicrophone)
            }

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

            Section("Almacenamiento") {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Carpeta de grabaciones")
                        Text(settings.recordingsFolder.path)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer()
                    Button("Cambiar\u{2026}") {
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = false
                        panel.canCreateDirectories = true
                        panel.allowsMultipleSelection = false
                        panel.directoryURL = settings.recordingsFolder
                        panel.prompt = "Elegir"
                        if panel.runModal() == .OK, let url = panel.url {
                            settings.recordingsFolder = url
                        }
                    }
                }
                Button("Restaurar por defecto") {
                    settings.recordingsFolder = Settings.defaultRecordingsFolder
                }
                .foregroundStyle(.secondary)
                .controlSize(.small)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 460)
    }
}
