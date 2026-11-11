import Foundation

#if canImport(FoundationModels)
import FoundationModels

/// On-device summary via the Foundation Models framework (iOS 26).
/// The deployment target is iOS 26 so this is the primary path. Notes are not
/// uploaded. If the model is missing or refuses the prompt, the caller falls
/// back to `ExtractiveSummarizer`.
struct FoundationModelsSummarizer: NoteSummarizer {
    var name: String { "foundation-models" }

    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability {
            return true
        }
        return false
    }

    static var statusText: String {
        switch SystemLanguageModel.default.availability {
        case .available:
            return "Apple Intelligence is on. Summaries and action items are generated on this iPhone."
        case .unavailable(let reason):
            switch reason {
            case .appleIntelligenceNotEnabled:
                return "Apple Intelligence is off. Summaries use a local extract of the transcript until you turn it on in Settings."
            case .deviceNotEligible:
                return "This iPhone does not support Apple Intelligence. Summaries use a local extract of the transcript."
            case .modelNotReady:
                return "The on-device model is still downloading. Summaries use a local extract of the transcript for now."
            @unknown default:
                return "The on-device model is unavailable. Summaries use a local extract of the transcript."
            }
        }
    }

    func summarize(transcript: String) async throws -> NoteSummary {
        let clipped = Self.clip(transcript)
        let session = LanguageModelSession(instructions: """
            You summarize a personal voice note for the person who recorded it.
            Stay faithful to the transcript. Do not invent names, dates, or tasks.
            Write the summary in the same language as the transcript.
            Action items are tasks the speaker asked for or committed to. If there are none, return an empty list.
            """)
        let response = try await session.respond(
            to: "Summarize this voice note:\n\n\(clipped)",
            generating: GeneratedNoteSummary.self
        )
        let content = response.content
        return NoteSummary(
            summary: content.summary.trimmingCharacters(in: .whitespacesAndNewlines),
            actionItems: content.actionItems
        )
    }

    private static func clip(_ transcript: String) -> String {
        let limit = 6_000
        guard transcript.count > limit else { return transcript }
        let end = transcript.index(transcript.startIndex, offsetBy: limit)
        return String(transcript[..<end]) + "\n\n[truncated]"
    }
}

@Generable
struct GeneratedNoteSummary {
    @Guide(description: "A 1 to 3 sentence summary in the same language as the voice note.")
    var summary: String

    @Guide(description: "Concrete action items from the note. An empty list when the speaker did not ask for or commit to any task.")
    var actionItems: [String]
}
#endif
