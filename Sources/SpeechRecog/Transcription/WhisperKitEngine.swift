import Foundation
import WhisperKit

final class WhisperKitEngine: TranscriptionEngine {
    private let modelName: String
    private let language: String?

    init(modelName: String, language: String?) {
        self.modelName = modelName
        self.language = language
    }

    func transcribe(
        audioURL: URL,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> Transcript {
        progress(0.02)
        let pipeline = try await WhisperKit(model: modelName)
        progress(0.20)

        var options = DecodingOptions()
        if let language { options.language = language }
        options.task = .transcribe
        options.withoutTimestamps = false
        options.wordTimestamps = false

        let results = try await pipeline.transcribe(
            audioPath: audioURL.path,
            decodeOptions: options
        )

        progress(0.95)
        let subtitles: [Subtitle] = results.flatMap { result in
            result.segments.map { seg in
                Subtitle(
                    start: TimeInterval(seg.start),
                    end: TimeInterval(seg.end),
                    text: seg.text.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
        }
        progress(1.0)
        return Transcript(segments: subtitles)
    }
}
