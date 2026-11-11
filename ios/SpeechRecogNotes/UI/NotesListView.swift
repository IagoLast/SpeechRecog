import SwiftUI

struct NotesListView: View {
    @Environment(VoiceNoteController.self) private var controller

    var body: some View {
        Group {
            if controller.notes.isEmpty && !controller.showsActivityBar {
                ContentUnavailableView {
                    Label("No voice notes", systemImage: "mic")
                } description: {
                    Text("Press the Action Button, or tap the microphone. SpeechRecog transcribes the note and writes a summary on this iPhone.")
                } actions: {
                    Button("Record") {
                        Task { await controller.toggleFromUI() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List {
                    ForEach(controller.notes) { note in
                        NavigationLink {
                            NoteDetailView(noteID: note.id)
                        } label: {
                            NoteRow(note: note)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                controller.delete(noteID: note.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .accessibilityIdentifier("notes.list")
            }
        }
        .navigationTitle("Notes")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await controller.toggleFromUI() }
                } label: {
                    Image(systemName: controller.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title3)
                        .foregroundStyle(controller.isRecording ? AnyShapeStyle(.red) : AnyShapeStyle(.primary))
                }
                .disabled(controller.isBusy)
                .accessibilityLabel(controller.isRecording ? "Stop recording" : "Start recording")
                .accessibilityIdentifier(controller.isRecording ? "stop.button" : "record.button")
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if controller.showsActivityBar {
                RecordingBar()
            }
        }
        .alert(
            "SpeechRecog",
            isPresented: Binding(
                get: { controller.lastError != nil },
                set: { if !$0 { controller.lastError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(controller.lastError ?? "")
        }
    }
}

private struct NoteRow: View {
    let note: VoiceNote

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.summary.isEmpty ? "Voice note" : note.summary)
                .font(.body)
                .lineLimit(2)
                .foregroundStyle(.primary)
            HStack(spacing: 8) {
                Text(note.durationLabel)
                Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}
