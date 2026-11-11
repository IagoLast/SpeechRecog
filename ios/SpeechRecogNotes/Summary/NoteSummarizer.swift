import Foundation

struct NoteSummary: Sendable, Equatable {
    var summary: String
    var actionItems: [String]
}

/// Recording calls this and does not care which implementation runs.
/// `FoundationModelsSummarizer` is the default on iOS 26 when Apple Intelligence
/// is available. `ExtractiveSummarizer` is the offline fallback. A cloud
/// implementation can conform to this protocol later without touching capture.
protocol NoteSummarizer: Sendable {
    var name: String { get }
    func summarize(transcript: String) async throws -> NoteSummary
}
