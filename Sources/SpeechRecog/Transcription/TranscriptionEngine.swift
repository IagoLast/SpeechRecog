import Foundation

struct Subtitle: Sendable, Equatable {
    let start: TimeInterval
    let end: TimeInterval
    let text: String
    var speaker: String? = nil
}

struct Transcript: Sendable {
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

struct TranscriptionConfiguration {
    var backend: TranscriptionBackend
    var whisperModel: String
    var language: String?

    init(settings: Settings) {
        backend = settings.transcriptionBackend
        whisperModel = settings.whisperModel
        language = settings.language
    }
}

enum TranscriptionEngineFactory {
    static func make(configuration: TranscriptionConfiguration) -> TranscriptionEngine {
        switch configuration.backend {
        case .whisperKit:
            return WhisperKitEngine(modelName: configuration.whisperModel, language: configuration.language)
        case .appleSpeech:
            return AppleSpeechEngine(language: configuration.language)
        case .qwen, .moss:
            return LocalModelsEngine(backend: configuration.backend, language: configuration.language)
        }
    }
}
