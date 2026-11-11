import AVFoundation
import SwiftUI

struct NoteDetailView: View {
    let noteID: UUID

    @Environment(VoiceNoteController.self) private var controller
    @Environment(\.dismiss) private var dismiss
    @StateObject private var player = NotePlayer()

    private var note: VoiceNote? {
        controller.notes.first { $0.id == noteID }
    }

    var body: some View {
        Group {
            if let note {
                content(note)
            } else {
                ContentUnavailableView("Note removed", systemImage: "trash")
            }
        }
        .navigationTitle("Voice note")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { player.stop() }
    }

    @ViewBuilder
    private func content(_ note: VoiceNote) -> some View {
        List {
            Section("Summary") {
                Text(note.summary)
                    .textSelection(.enabled)
            }
            if !note.actionItems.isEmpty {
                Section("Action items") {
                    ForEach(Array(note.actionItems.enumerated()), id: \.offset) { _, item in
                        Label(item, systemImage: "checkmark.circle")
                            .textSelection(.enabled)
                    }
                }
            }
            Section("Transcript") {
                if note.transcript.isEmpty {
                    Text("No transcript yet.")
                        .foregroundStyle(.secondary)
                } else {
                    Text(note.transcript)
                        .textSelection(.enabled)
                }
            }
            Section("Recording") {
                LabeledContent("Length", value: note.durationLabel)
                LabeledContent("Saved", value: note.createdAt.formatted(date: .abbreviated, time: .shortened))
                Button {
                    player.toggle(url: controller.audioURL(for: note))
                } label: {
                    Label(player.isPlaying ? "Pause" : "Play", systemImage: player.isPlaying ? "pause.fill" : "play.fill")
                }
                .disabled(controller.isRecording || controller.isBusy)
                Button("Transcribe again") {
                    Task { await controller.reprocess(noteID: note.id) }
                }
                .disabled(controller.isRecording || controller.isBusy)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: shareText(note)) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    controller.delete(noteID: note.id)
                    dismiss()
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Delete")
            }
        }
    }

    private func shareText(_ note: VoiceNote) -> String {
        var lines = [note.summary]
        if !note.actionItems.isEmpty {
            lines.append("")
            lines.append(contentsOf: note.actionItems.map { "• \($0)" })
        }
        if !note.transcript.isEmpty {
            lines.append("")
            lines.append(note.transcript)
        }
        return lines.joined(separator: "\n")
    }
}

@MainActor
final class NotePlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var isPlaying = false
    private var player: AVAudioPlayer?

    func toggle(url: URL) {
        if isPlaying {
            stop()
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true)
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.play()
            self.player = player
            isPlaying = true
        } catch {
            isPlaying = false
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.player = nil
        }
    }
}
