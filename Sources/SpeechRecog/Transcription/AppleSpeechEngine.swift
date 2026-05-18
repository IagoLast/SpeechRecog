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
            throw NSError(
                domain: "AppleSpeech",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Reconocimiento no disponible para \(locale.identifier)"]
            )
        }

        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        request.taskHint = .dictation
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }

        progress(0.10)

        let delegate = RecognitionDelegate()
        let final: SFSpeechRecognitionResult = try await withCheckedThrowingContinuation { cont in
            delegate.continuation = cont
            delegate.task = recognizer.recognitionTask(with: request, delegate: delegate)
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
            throw NSError(
                domain: "AppleSpeech",
                code: Int(status.rawValue),
                userInfo: [NSLocalizedDescriptionKey: "Permiso de reconocimiento de voz denegado"]
            )
        }
    }

    /// Apple Speech returns per-word segments; group them into ~8s subtitle chunks.
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

/// Holds the continuation across the SFSpeechRecognitionTask lifecycle.
/// `didFinishSuccessfully` is the only callback guaranteed to fire for both
/// the "got a final transcription" and "task finished but no speech detected"
/// paths, so we always resume from there if we haven't already.
private final class RecognitionDelegate: NSObject, SFSpeechRecognitionTaskDelegate {
    var continuation: CheckedContinuation<SFSpeechRecognitionResult, Error>?
    var task: SFSpeechRecognitionTask?
    private var lastResult: SFSpeechRecognitionResult?
    private let lock = NSLock()

    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {
        // Partial results are disabled, but defensively cache anything we get.
    }

    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition result: SFSpeechRecognitionResult) {
        lock.lock(); defer { lock.unlock() }
        lastResult = result
    }

    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        lock.lock()
        let cont = continuation
        continuation = nil
        let result = lastResult
        lock.unlock()
        guard let cont else { return }

        if let result {
            cont.resume(returning: result)
        } else if let taskError = task.error {
            cont.resume(throwing: taskError)
        } else {
            cont.resume(throwing: NSError(
                domain: "AppleSpeech",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "No se detectó habla en la grabación"]
            ))
        }
    }
}
