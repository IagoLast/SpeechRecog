import AudioCommon
import Foundation
import MossTranscribe
import Qwen3ASR
import SpeechVAD

/// Models are scoped to one job so switching engines releases their weights.
/// This nonisolated async entry point runs inference away from the main actor.
final class LocalModelsEngine: TranscriptionEngine {
    private let backend: TranscriptionBackend
    private let language: String?
    private static let sampleRate = LocalTranscriptSupport.sampleRate

    init(backend: TranscriptionBackend, language: String?) {
        self.backend = backend
        self.language = LocalTranscriptSupport.languageName(language)
    }

    func transcribe(
        audioURL: URL,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> Transcript {
        progress(0.01)
        // Decode incrementally: avoid holding an entire stereo 48 kHz PCM file.
        var audio: [Float] = []
        for try await chunk in AudioFileLoader.stream(
            url: audioURL, options: .init(targetSampleRate: Self.sampleRate)
        ) {
            audio.append(contentsOf: chunk.samples)
        }
        guard !audio.isEmpty else { throw LocalTranscriptionError.emptyAudio }
        progress(0.04)
        let vad = try await SileroVADModel.fromPretrained { fraction, _ in
            progress(0.04 + fraction * 0.04)
        }
        let speech = vad.detectSpeech(audio: audio, sampleRate: Self.sampleRate)
        let ranges = speech.map {
            Int($0.startTime * Float(Self.sampleRate))..<Int($0.endTime * Float(Self.sampleRate))
        }
        guard !ranges.isEmpty else {
            progress(1)
            return Transcript(segments: [])
        }
        switch backend {
        case .qwen:
            return try await transcribeQwen(audio: audio, speech: ranges, progress: progress)
        case .moss:
            return try await transcribeMoss(audio: audio, speech: ranges, progress: progress)
        default:
            preconditionFailure("LocalModelsEngine requires Qwen or MOSS")
        }
    }

    private func transcribeQwen(
        audio: [Float], speech: [Range<Int>], progress: @escaping @Sendable (Double) -> Void
    ) async throws -> Transcript {
        let model = try await Qwen3ASRModel.fromPretrained(
            modelId: "aufklarer/Qwen3-ASR-1.7B-MLX-8bit"
        ) { fraction, _ in progress(0.08 + fraction * 0.27) }
        defer { model.unload() }
        let aligner = try await Qwen3ForcedAligner.fromPretrained(
            modelId: "aufklarer/Qwen3-ForcedAligner-0.6B-8bit"
        ) { fraction, _ in progress(0.35 + fraction * 0.15) }

        let chunks = LocalTranscriptSupport.speechChunks(audio: audio, ranges: speech)
        var subtitles: [Subtitle] = []
        for (index, range) in chunks.enumerated() {
            try Task.checkCancellation()
            let chunkSubtitles = try autoreleasepool {
                let samples = Array(audio[range])
                let text = try model.transcribeCheckingCancellation(
                    audio: samples, sampleRate: Self.sampleRate,
                    options: .init(maxTokens: 1_024, language: language)
                ).trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return [Subtitle]() }
                let words = aligner.align(
                    audio: samples, text: text, sampleRate: Self.sampleRate,
                    language: language ?? "English"
                )
                let timed = words.compactMap {
                    LocalTranscriptSupport.subtitle(
                        start: Double($0.startTime), end: Double($0.endTime), text: $0.text,
                        duration: Double(samples.count) / Double(Self.sampleRate),
                        offset: Double(range.lowerBound) / Double(Self.sampleRate)
                    )
                }
                guard !timed.isEmpty else { throw LocalTranscriptionError.missingTimestamps }
                return LocalTranscriptSupport.groupWords(timed)
            }
            subtitles.append(contentsOf: chunkSubtitles)
            progress(0.5 + 0.49 * Double(index + 1) / Double(chunks.count))
        }
        guard !subtitles.isEmpty else { throw LocalTranscriptionError.missingTimestamps }
        progress(1)
        return Transcript(segments: subtitles)
    }

    private func transcribeMoss(
        audio: [Float], speech: [Range<Int>], progress: @escaping @Sendable (Double) -> Void
    ) async throws -> Transcript {
        let model = try await MossMLXModel.fromPretrained(variant: .int8) { fraction, _ in
            progress(0.08 + fraction * 0.32)
        }
        let chunkSize = LocalTranscriptSupport.mossChunkSeconds * Self.sampleRate
        let count = (audio.count + chunkSize - 1) / chunkSize
        var subtitles: [Subtitle] = []
        for index in 0..<count {
            try Task.checkCancellation()
            let range = (index * chunkSize)..<min((index + 1) * chunkSize, audio.count)
            if speech.contains(where: { $0.overlaps(range) }) {
                let duration = Double(range.count) / Double(Self.sampleRate)
                var instruction = MossMLXModel.defaultInstruction
                if let language {
                    instruction += "\nThe spoken language is \(language). Transcribe in the original language."
                }
                let result = try model.transcribeDetailed(
                    audio: Array(audio[range]), sampleRate: Self.sampleRate,
                    options: .init(maxTokens: max(2_048, Int(ceil(duration * 16))), encoderBatchSize: 2),
                    instruction: instruction
                )
                // Never replace an existing SRT with a silently truncated transcript.
                guard result.metrics.stopReason == .endOfSequence else {
                    throw LocalTranscriptionError.incompleteTranscript
                }
                let segments = result.segments.compactMap {
                    LocalTranscriptSupport.subtitle(
                        start: $0.startTime, end: $0.endTime, text: $0.text, duration: duration,
                        offset: Double(range.lowerBound) / Double(Self.sampleRate),
                        speaker: LocalTranscriptSupport.speakerLabel($0.speaker, chunk: index, chunkCount: count)
                    )
                }
                guard !segments.isEmpty else { throw LocalTranscriptionError.missingTimestamps }
                subtitles.append(contentsOf: segments)
            }
            progress(0.4 + 0.59 * Double(index + 1) / Double(count))
        }
        progress(1)
        return Transcript(segments: subtitles)
    }
}

enum LocalTranscriptionError: LocalizedError {
    case emptyAudio
    case missingTimestamps
    case incompleteTranscript

    var errorDescription: String? {
        switch self {
        case .emptyAudio: return "La grabación no contiene audio."
        case .missingTimestamps:
            return "El modelo no ha generado tiempos válidos para los subtítulos. Se conserva el SRT anterior, si existe."
        case .incompleteTranscript:
            return "MOSS ha alcanzado su límite antes de terminar. Prueba a retranscribir con Qwen. Se conserva el SRT anterior, si existe."
        }
    }
}
