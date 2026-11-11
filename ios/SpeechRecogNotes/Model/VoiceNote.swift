import Foundation

struct VoiceNote: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var createdAt: Date
    var duration: TimeInterval
    var transcript: String
    var summary: String
    var actionItems: [String]
    var audioFilename: String
    /// "foundation-models", "extractive", or "none".
    var summarizer: String

    var durationLabel: String {
        let total = max(0, Int(duration.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
