import AVFoundation
import Foundation
import Speech

/// File transcription adapted from the Mac target's `AppleSpeechEngine`.
/// Voice notes need the full text rather than subtitle cues, and Apple's URL
/// recognizer is unreliable past about a minute, so longer recordings are
/// split before recognition.
struct NoteTranscriber: Sendable {
    var locale: Locale

    init(languageCode: String) {
        locale = languageCode.isEmpty ? .current : Locale(identifier: languageCode)
    }

    func transcribe(audioURL: URL) async throws -> String {
        try await Self.requestAuthorization()
        let chunks: AudioChunks
        do {
            chunks = try await AudioChunks.make(from: audioURL)
        } catch {
            chunks = AudioChunks(urls: [audioURL], temporaryDirectory: nil)
        }
        defer { chunks.cleanup() }

        var parts: [String] = []
        var lastError: Error?
        for url in chunks.urls {
            do {
                let text = try await recognize(url).trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty { parts.append(text) }
            } catch {
                lastError = error
            }
        }
        let joined = parts.joined(separator: " ")
        if joined.isEmpty {
            throw lastError ?? NoteError.noSpeech
        }
        return joined
    }

    static func requestAuthorization() async throws {
        var status = SFSpeechRecognizer.authorizationStatus()
        if status == .notDetermined {
            status = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
            }
        }
        guard status == .authorized else {
            throw NoteError.speechDenied
        }
    }

    private func recognize(_ url: URL) async throws -> String {
        guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else {
            throw NoteError.recognizerUnavailable(locale.identifier)
        }
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = false
        request.taskHint = .dictation
        request.addsPunctuation = true
        if recognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }

        let delegate = RecognitionDelegate()
        let result: SFSpeechRecognitionResult = try await withCheckedThrowingContinuation { continuation in
            delegate.continuation = continuation
            delegate.task = recognizer.recognitionTask(with: request, delegate: delegate)
        }
        return result.bestTranscription.formattedString
    }
}

/// Same lifecycle as `AppleSpeechEngine`'s delegate: `didFinishSuccessfully`
/// is the callback that fires both when a final result exists and when the
/// file contained no speech.
private final class RecognitionDelegate: NSObject, SFSpeechRecognitionTaskDelegate {
    var continuation: CheckedContinuation<SFSpeechRecognitionResult, Error>?
    var task: SFSpeechRecognitionTask?
    private var lastResult: SFSpeechRecognitionResult?
    private let lock = NSLock()

    func speechRecognitionDidDetectSpeech(_ task: SFSpeechRecognitionTask) {}

    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didHypothesizeTranscription transcription: SFTranscription) {}

    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishRecognition result: SFSpeechRecognitionResult) {
        lock.lock()
        lastResult = result
        lock.unlock()
    }

    func speechRecognitionTask(_ task: SFSpeechRecognitionTask, didFinishSuccessfully successfully: Bool) {
        lock.lock()
        let continuation = continuation
        self.continuation = nil
        let result = lastResult
        let taskError = task.error
        self.task = nil
        lock.unlock()
        guard let continuation else { return }
        if let result, successfully || !result.bestTranscription.formattedString.isEmpty {
            continuation.resume(returning: result)
        } else if let taskError {
            continuation.resume(throwing: taskError)
        } else {
            continuation.resume(throwing: NoteError.noSpeech)
        }
    }
}

private struct AudioChunks {
    var urls: [URL]
    var temporaryDirectory: URL?

    func cleanup() {
        guard let temporaryDirectory else { return }
        try? FileManager.default.removeItem(at: temporaryDirectory)
    }

    static func make(from source: URL, maxSeconds: TimeInterval = 50) async throws -> AudioChunks {
        let asset = AVURLAsset(url: source)
        let duration = try await asset.load(.duration)
        let total = duration.seconds
        guard total.isFinite, total > maxSeconds + 0.5 else {
            return AudioChunks(urls: [source], temporaryDirectory: nil)
        }

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("speechrecog-chunks-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        var urls: [URL] = []
        var start = 0.0
        var index = 0
        while start < total - 0.2 {
            let end = min(start + maxSeconds, total)
            let output = directory.appendingPathComponent("chunk-\(index).m4a")
            guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
                throw NoteError.exportFailed
            }
            session.outputURL = output
            session.outputFileType = .m4a
            session.timeRange = CMTimeRange(
                start: CMTime(seconds: start, preferredTimescale: 600),
                end: CMTime(seconds: end, preferredTimescale: 600)
            )
            try await export(session)
            urls.append(output)
            start = end
            index += 1
        }
        return AudioChunks(urls: urls, temporaryDirectory: directory)
    }

    private static func export(_ session: AVAssetExportSession) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            session.exportAsynchronously {
                if session.status == .completed {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: session.error ?? NoteError.exportFailed)
                }
            }
        }
    }
}
