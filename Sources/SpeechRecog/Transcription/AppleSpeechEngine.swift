import Foundation
import Speech

final class AppleSpeechEngine: TranscriptionEngine {
    private let language: String?

    init(language: String?) {
        self.language = language
    }

    func transcribe(
        audioURL: URL,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> Transcript {
        try await Self.requestAuthorization()

        let locale = language.flatMap(Locale.init(identifier:)) ?? Locale.current
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw NSError(domain: "AppleSpeech", code: -1, userInfo: [NSLocalizedDescriptionKey: "Reconocimiento no disponible para \(locale.identifier)"])
        }

        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        request.taskHint = .dictation
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }

        progress(0.10)

        let final: SFSpeechRecognitionResult = try await withCheckedThrowingContinuation { cont in
            var resumed = false
            recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    if !resumed { resumed = true; cont.resume(throwing: error) }
                    return
                }
                guard let result else { return }
                if result.isFinal, !resumed {
                    resumed = true
                    cont.resume(returning: result)
                }
            }
        }

        progress(0.95)
        let perWord = final.bestTranscription.segments.map {
            Subtitle(
                start: $0.timestamp,
                end: $0.timestamp + $0.duration,
                text: $0.substring
            )
        }
        progress(1.0)
        return Transcript(segments: Self.collapse(segments: perWord))
    }

    private static func requestAuthorization() async throws {
        let status: SFSpeechRecognizerAuthorizationStatus = await withCheckedContinuation { cont in
            SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0) }
        }
        guard status == .authorized else {
            throw NSError(domain: "AppleSpeech", code: Int(status.rawValue), userInfo: [NSLocalizedDescriptionKey: "Permiso de reconocimiento de voz denegado"])
        }
    }

    /// Apple Speech returns per-word segments; group them into ~10s subtitle chunks.
    private static func collapse(segments: [Subtitle], maxDuration: TimeInterval = 8) -> [Subtitle] {
        var out: [Subtitle] = []
        var current: Subtitle?
        for seg in segments {
            if var c = current, seg.end - c.start <= maxDuration {
                c = Subtitle(start: c.start, end: seg.end, text: c.text + " " + seg.text)
                current = c
            } else {
                if let c = current { out.append(c) }
                current = seg
            }
        }
        if let c = current { out.append(c) }
        return out
    }
}
