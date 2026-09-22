import AppKit
import SwiftUI

struct RecordingsView: View {
    @ObservedObject var coordinator: RecordingCoordinator
    @ObservedObject var settings: Settings
    @State private var recordings: [Recording] = []
    @State private var selectedRecording: Recording?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Grabaciones").font(.title2.bold())
                    Text(settings.recordingsFolder.path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(settings.recordingsFolder.path)
                }
                Spacer()
                Button("Actualizar", systemImage: "arrow.clockwise", action: reload)
            }

            activityStatus

            if recordings.isEmpty {
                ContentUnavailableView(
                    "Todavía no hay grabaciones",
                    systemImage: "waveform",
                    description: Text("Las grabaciones guardadas en esta carpeta aparecerán aquí para transcribirlas con el modelo que elijas.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(recordings, id: \.audioURL) { recording in
                        recordingRow(recording)
                    }
                }
                .listStyle(.inset)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Text("\(recordings.count) grabaciones · El audio original se conserva al transcribir.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .onAppear(perform: reload)
        .onChange(of: settings.recordingsFolder) { _, _ in reload() }
        .onChange(of: coordinator.transcribingRecording?.audioURL) { _, _ in reload() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            reload()
        }
        .sheet(item: $selectedRecording) { recording in
            TranscriptionSheet(recording: recording, coordinator: coordinator) { configuration in
                selectedRecording = nil
                Task {
                    await coordinator.retranscribe(recording: recording, configuration: configuration)
                    reload()
                }
            }
        }
    }

    @ViewBuilder
    private var activityStatus: some View {
        switch coordinator.state {
        case .idle:
            EmptyView()
        case .starting, .recording:
            Label("Hay una grabación en curso. Podrás transcribir cuando termine.", systemImage: "record.circle")
                .font(.callout)
                .foregroundStyle(.secondary)
        case .transcribing(let progress):
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Transcribiendo…").fontWeight(.medium)
                    if let recording = coordinator.transcribingRecording {
                        Text(recording.audioURL.lastPathComponent)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Spacer()
                    Text(progress, format: .percent.precision(.fractionLength(0)))
                        .monospacedDigit()
                }
                ProgressView(value: progress)
            }
            .padding(12)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func recordingRow(_ recording: Recording) -> some View {
        let hasSubtitles = FileManager.default.fileExists(atPath: recording.subtitleURL.path)
        let isTranscribing = coordinator.transcribingRecording?.audioURL == recording.audioURL

        return HStack(spacing: 14) {
            Image(systemName: "waveform")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 5) {
                Text(recording.createdAt, format: .dateTime.day().month(.wide).year().hour().minute())
                    .fontWeight(.medium)
                Text(recording.audioURL.lastPathComponent)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(recording.audioURL.lastPathComponent)
                Text(isTranscribing ? "Transcribiendo…" : hasSubtitles ? "Con subtítulos" : "Sin transcribir")
                    .font(.caption)
                    .foregroundStyle(isTranscribing ? Color.accentColor : .secondary)
            }

            Spacer(minLength: 12)

            Menu {
                Button("Reproducir audio") { NSWorkspace.shared.open(recording.audioURL) }
                if hasSubtitles {
                    Button("Abrir subtítulos") { NSWorkspace.shared.open(recording.subtitleURL) }
                }
                Button("Mostrar en Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([recording.audioURL])
                }
            } label: {
                Image(systemName: "ellipsis")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .accessibilityLabel("Opciones de la grabación")

            Button(hasSubtitles ? "Retranscribir…" : "Transcribir…") {
                selectedRecording = recording
            }
            .buttonStyle(.bordered)
            .disabled(coordinator.state != .idle)
        }
        .padding(.vertical, 10)
    }

    private func reload() {
        recordings = RecordingsStore(folder: settings.recordingsFolder).listRecordings()
    }
}

private struct TranscriptionSheet: View {
    let recording: Recording
    @ObservedObject var coordinator: RecordingCoordinator
    let onTranscribe: (TranscriptionConfiguration) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var configuration: TranscriptionConfiguration

    init(
        recording: Recording,
        coordinator: RecordingCoordinator,
        onTranscribe: @escaping (TranscriptionConfiguration) -> Void
    ) {
        self.recording = recording
        self.coordinator = coordinator
        self.onTranscribe = onTranscribe
        _configuration = State(initialValue: TranscriptionConfiguration(settings: coordinator.settings))
    }

    var body: some View {
        let hasSubtitles = FileManager.default.fileExists(atPath: recording.subtitleURL.path)

        VStack(alignment: .leading, spacing: 16) {
            Text(hasSubtitles ? "Retranscribir grabación" : "Transcribir grabación")
                .font(.title2.bold())
            Text(recording.audioURL.lastPathComponent)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .truncationMode(.middle)

            Form {
                TranscriptionOptionsView(
                    backend: $configuration.backend,
                    whisperModel: $configuration.whisperModel,
                    language: $configuration.language
                )
            }
            .formStyle(.grouped)
            .frame(height: 220)

            Text(hasSubtitles
                 ? "Se conservará el audio original. Los subtítulos actuales se sustituirán cuando la transcripción termine correctamente."
                 : "Se conservará el audio original y se guardarán los subtítulos junto a la grabación.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if coordinator.state != .idle {
                Text("Espera a que termine la grabación o transcripción en curso.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button("Cancelar") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(hasSubtitles ? "Retranscribir" : "Transcribir") {
                    onTranscribe(configuration)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(coordinator.state != .idle)
            }
        }
        .padding(24)
        .frame(width: 580)
    }
}
