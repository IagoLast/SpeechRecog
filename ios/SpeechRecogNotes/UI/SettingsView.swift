import AVFoundation
import Speech
import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var model = settings
        Form {
            Section {
                Picker("Language", selection: $model.languageCode) {
                    Text("System").tag("")
                    Text("English").tag("en-US")
                    Text("Spanish").tag("es-ES")
                    Text("Portuguese").tag("pt-BR")
                    Text("French").tag("fr-FR")
                    Text("German").tag("de-DE")
                }
            } header: {
                Text("Transcription")
            } footer: {
                Text("Apple's speech recognizer uses this language. The summary follows the language of the transcript.")
            }

            Section {
                Text(SummarizerStatus.detail)
            } header: {
                Text("Summary")
            } footer: {
                Text("Summaries stay on this iPhone. Apple Intelligence is used when it is available. Otherwise SpeechRecog keeps the first sentences and any lines that look like tasks.")
            }

            Section {
                LabeledContent("Microphone", value: microphoneStatus)
                LabeledContent("Speech recognition", value: speechStatus)
                if microphoneBlocked || speechBlocked {
                    Button("Open Settings") {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        UIApplication.shared.open(url)
                    }
                }
            } header: {
                Text("Access")
            }

            Section {
                instruction("1", "Open Settings → Action Button.")
                instruction("2", "Swipe to Shortcut.")
                instruction("3", "Choose SpeechRecog → Voice Note.")
                instruction("4", "Leave Open When Run off if you want the press to record without opening the app.")
                instruction("5", "Press the Action Button to start. Press it again, or tap Stop on the Lock Screen, to finish the note.")
            } header: {
                Text("Action Button")
            } footer: {
                Text("The first press after installing opens SpeechRecog if the microphone has not been allowed yet, or if iOS refuses to start the microphone in the background. Turn on Live Activities for SpeechRecog. Without one, iOS stops a background recording.")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func instruction(_ number: String, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(number)
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 16, alignment: .trailing)
            Text(text)
        }
    }

    private var microphoneStatus: String {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: return "Allowed"
        case .denied: return "Blocked"
        case .undetermined: return "Not asked"
        @unknown default: return "Unknown"
        }
    }

    private var speechStatus: String {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized: return "Allowed"
        case .denied, .restricted: return "Blocked"
        case .notDetermined: return "Not asked"
        @unknown default: return "Unknown"
        }
    }

    private var microphoneBlocked: Bool {
        AVAudioApplication.shared.recordPermission == .denied
    }

    private var speechBlocked: Bool {
        let status = SFSpeechRecognizer.authorizationStatus()
        return status == .denied || status == .restricted
    }
}
