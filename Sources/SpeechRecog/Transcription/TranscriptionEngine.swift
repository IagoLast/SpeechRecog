import Foundation

struct Subtitle {
    let start: TimeInterval
    let end: TimeInterval
    let text: String
}

struct Transcript {
    let segments: [Subtitle]
    var fullText: String {
        segments.map(\.text).joined(separator: " ")
    }
}

protocol TranscriptionEngine {
    func transcribe(
        audioURL: URL,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> Transcript
}

enum TranscriptionEngineFactory {
    static func make(settings: Settings) throws -> TranscriptionEngine {
        switch settings.transcriptionBackend {
        case .whisperKit:
            return WhisperKitEngine(modelName: settings.whisperModel, language: settings.language)
        case .appleSpeech:
            return AppleSpeechEngine(language: settings.language)
        }
    }
}
