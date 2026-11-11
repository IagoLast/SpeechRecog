import ActivityKit
import AppIntents
import SpeechRecogShared
import SwiftUI
import WidgetKit

struct RecordingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RecordingActivityAttributes.self) { context in
            LockScreenRecordingView(state: context.state)
                .padding(.horizontal, 4)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "mic.fill")
                        .foregroundStyle(context.state.phase == .recording ? .red : .secondary)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.phase == .recording {
                        Text(context.state.startedAt, style: .timer)
                            .monospacedDigit()
                            .font(.title3)
                    } else {
                        Text(context.state.phase.title)
                            .font(.caption)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    LiveActivityStatus(state: context.state)
                }
            } compactLeading: {
                Image(systemName: "mic.fill")
                    .foregroundStyle(context.state.phase == .recording ? .red : .secondary)
            } compactTrailing: {
                if context.state.phase == .recording {
                    Text(context.state.startedAt, style: .timer)
                        .monospacedDigit()
                        .font(.caption2)
                        .frame(width: 52)
                } else {
                    Image(systemName: "waveform")
                }
            } minimal: {
                Image(systemName: "mic.fill")
                    .foregroundStyle(.red)
            }
        }
    }
}

private struct LockScreenRecordingView: View {
    let state: RecordingActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: state.phase == .recording ? "mic.fill" : "waveform")
                .font(.title2)
                .foregroundStyle(state.phase == .recording ? .red : .secondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text("Voice note")
                    .font(.headline)
                Text(state.phase == .recording ? "Recording" : state.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            LiveActivityStatus(state: state)
        }
    }
}

private struct LiveActivityStatus: View {
    let state: RecordingActivityAttributes.ContentState

    var body: some View {
        if state.phase == .recording {
            VStack(alignment: .trailing, spacing: 6) {
                Text(state.startedAt, style: .timer)
                    .font(.title3.monospacedDigit())
                Button(intent: StopVoiceNoteIntent()) {
                    Label("Stop", systemImage: "stop.fill")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.red, in: Capsule())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("liveactivity.stop")
            }
        } else {
            Text(state.phase.title)
                .font(.subheadline.weight(.semibold))
        }
    }
}

private extension RecordingActivityAttributes.Phase {
    var title: String {
        switch self {
        case .recording: return "Recording"
        case .transcribing: return "Transcribing"
        case .summarizing: return "Summarizing"
        case .done: return "Saved"
        }
    }
}
