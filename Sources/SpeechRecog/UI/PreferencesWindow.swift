import AppKit
import SwiftUI

enum PreferencesWindow {
    @MainActor
    static func make(coordinator: RecordingCoordinator) -> NSWindow {
        let view = PreferencesView(coordinator: coordinator)
        let host = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: host)
        window.title = "SpeechRecog · Preferencias"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setContentSize(NSSize(width: 900, height: 650))
        window.contentMinSize = NSSize(width: 760, height: 560)
        window.isReleasedWhenClosed = false
        window.center()
        return window
    }
}

private struct PreferencesView: View {
    @ObservedObject var coordinator: RecordingCoordinator

    var body: some View {
        TabView {
            GeneralPreferencesView(settings: coordinator.settings)
                .tabItem { Label("General", systemImage: "gearshape") }

            RecordingsView(coordinator: coordinator, settings: coordinator.settings)
                .tabItem { Label("Grabaciones", systemImage: "waveform") }
        }
        .padding(20)
        .frame(minWidth: 760, minHeight: 560)
    }
}

private struct GeneralPreferencesView: View {
    @ObservedObject var settings: Settings

    var body: some View {
        Form {
            Section("Audio") {
                Toggle("Incluir micrófono", isOn: $settings.includeMicrophone)
            }

            Section("Transcripción") {
                TranscriptionOptionsView(
                    backend: $settings.transcriptionBackend,
                    whisperModel: $settings.whisperModel,
                    language: $settings.language
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
    }
}

struct TranscriptionOptionsView: View {
    @Binding var backend: TranscriptionBackend
    @Binding var whisperModel: String
    @Binding var language: String?

    var body: some View {
        Picker("Modelo", selection: $backend) {
            ForEach(TranscriptionBackend.allCases) { backend in
                Text(backend.displayName).tag(backend)
            }
        }

        if backend == .whisperKit {
            Picker("Modelo Whisper", selection: $whisperModel) {
                ForEach(WhisperModel.allCases) { model in
                    Text(model.displayName).tag(model.rawValue)
                }
            }
        }

        if let detail = backend.detail {
            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }

        TextField(
            "Idioma (BCP-47, vacío = auto)",
            text: Binding(
                get: { language ?? "" },
                set: {
                    let value = $0.trimmingCharacters(in: .whitespacesAndNewlines)
                    language = value.isEmpty ? nil : value
                }
            )
        )
    }
}
