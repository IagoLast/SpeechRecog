import AVFoundation
import XCTest
@testable import SpeechRecog

/// Opt-in tests exercise actual downloads, Metal kernels, inference, and alignment.
final class LocalModelsIntegrationTests: XCTestCase {
    func testQwenTranscribesSpanishAudioWithSubtitleTimes() async throws {
        try await check(backend: .qwen)
    }

    func testMossTranscribesSpanishAudioWithSpeakerLabels() async throws {
        try await check(backend: .moss)
    }

    private func check(backend: TranscriptionBackend) async throws {
        let environment = ProcessInfo.processInfo.environment
        try XCTSkipUnless(environment["SPEECHRECOG_TEST_MODEL"] == backend.rawValue)
        let path = try XCTUnwrap(environment["SPEECHRECOG_TEST_AUDIO"])
        let url = URL(fileURLWithPath: path)
        let original = try Data(contentsOf: url)
        let file = try AVAudioFile(forReading: url)
        let duration = Double(file.length) / file.processingFormat.sampleRate
        let result = try await LocalModelsEngine(backend: backend, language: "es-ES").transcribe(
            audioURL: url, progress: { value in print("Model progress: \(Int(value * 100))%") }
        )
        XCTAssertFalse(result.segments.isEmpty)
        let text = result.fullText.lowercased()
        XCTAssertTrue(text.contains("proyecto"), result.fullText)
        XCTAssertTrue(text.contains("viernes"), result.fullText)
        for segment in result.segments {
            XCTAssertGreaterThanOrEqual(segment.start, 0)
            XCTAssertGreaterThan(segment.end, segment.start)
            XCTAssertLessThanOrEqual(segment.end, duration + 0.1)
            if backend == .moss { XCTAssertNotNil(segment.speaker) }
        }
        XCTAssertEqual(try Data(contentsOf: url), original)
        print("\(backend.rawValue): \(result.fullText)")
    }
}
