import Foundation

enum SummarizerFactory {
    static func make() -> any NoteSummarizer {
        #if canImport(FoundationModels)
        if FoundationModelsSummarizer.isAvailable {
            return FoundationModelsSummarizer()
        }
        #endif
        return ExtractiveSummarizer()
    }
}

enum SummarizerStatus {
    static var detail: String {
        #if canImport(FoundationModels)
        FoundationModelsSummarizer.statusText
        #else
        "This build does not include the Foundation Models framework. Summaries use a local extract of the transcript."
        #endif
    }
}
