import SwiftUI

struct RecordingBar: View {
    @Environment(VoiceNoteController.self) private var controller

    var body: some View {
        HStack(spacing: 12) {
            switch controller.phase {
            case .recording(let startedAt):
                Circle()
                    .fill(.red)
                    .frame(width: 10, height: 10)
                    .accessibilityHidden(true)
                Text(startedAt, style: .timer)
                    .font(.body.monospacedDigit())
                    .accessibilityLabel("Recording")
                Spacer()
                Button("Stop") {
                    Task { await controller.stopAndProcess() }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .accessibilityIdentifier("stop.button")
            case .transcribing:
                ProgressView()
                Text("Transcribing…")
                Spacer()
            case .summarizing:
                ProgressView()
                Text("Summarizing…")
                Spacer()
            case .idle:
                EmptyView()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.bar)
    }
}
