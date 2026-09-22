import XCTest
@testable import SpeechRecog

final class LocalTranscriptSupportTests: XCTestCase {
    func testLocaleHintsAreConvertedToModelLanguageNames() {
        XCTAssertEqual(LocalTranscriptSupport.languageName("es-ES"), "Spanish")
        XCTAssertEqual(LocalTranscriptSupport.languageName("en_US"), "English")
        XCTAssertNil(LocalTranscriptSupport.languageName("  "))
        XCTAssertNil(LocalTranscriptSupport.languageName(nil))
    }

    func testChunkTimestampsKeepTheOriginalOffsetAndClampToAudio() throws {
        let segment = try XCTUnwrap(LocalTranscriptSupport.subtitle(
            start: -0.2, end: 8, text: " Hola ", duration: 5, offset: 120
        ))
        XCTAssertEqual(segment, Subtitle(start: 120, end: 125, text: "Hola"))
        XCTAssertNil(LocalTranscriptSupport.subtitle(start: .nan, end: 2, text: "Hola", duration: 5))
        XCTAssertNil(LocalTranscriptSupport.subtitle(start: 6, end: 8, text: "Hola", duration: 5))
        XCTAssertNil(LocalTranscriptSupport.subtitle(start: 2, end: 1, text: "Hola", duration: 5))
    }

    func testGroupingRespectsPausesAndSentenceBoundaries() {
        let result = LocalTranscriptSupport.groupWords([
            Subtitle(start: 30, end: 30.5, text: "Hola"),
            Subtitle(start: 30.5, end: 31, text: "mundo."),
            Subtitle(start: 31.1, end: 31.5, text: "Otro"),
            Subtitle(start: 34, end: 34.5, text: "saludo.")
        ])
        XCTAssertEqual(result.map(\.text), ["Hola mundo.", "Otro", "saludo."])
        XCTAssertEqual(result.map(\.start), [30, 31.1, 34])
    }

    func testLongSpeechIsSplitWithoutLosingOrDuplicatingSamples() {
        let rate = LocalTranscriptSupport.sampleRate
        let audio = [Float](repeating: 0.1, count: 70 * rate)
        let chunks = LocalTranscriptSupport.speechChunks(audio: audio, ranges: [rate..<(69 * rate)])
        XCTAssertGreaterThan(chunks.count, 2)
        XCTAssertTrue(chunks.allSatisfy { $0.count <= 25 * rate })
        for pair in zip(chunks, chunks.dropFirst()) {
            XCTAssertEqual(pair.0.upperBound, pair.1.lowerBound)
        }
        XCTAssertEqual(chunks.first?.lowerBound, rate - rate / 5)
        XCTAssertEqual(chunks.last?.upperBound, 69 * rate + rate / 5)
    }

    func testSilentGapsAreNotCollapsedAndPaddedSpeechIsNotDuplicated() {
        let rate = LocalTranscriptSupport.sampleRate
        let audio = [Float](repeating: 0, count: 60 * rate)
        let chunks = LocalTranscriptSupport.speechChunks(
            audio: audio, ranges: [0..<rate, rate..<(2 * rate), (50 * rate)..<(51 * rate)]
        )
        XCTAssertEqual(chunks.count, 2)
        XCTAssertEqual(chunks[0].lowerBound, 0)
        XCTAssertGreaterThan(chunks[1].lowerBound, 49 * rate)
    }

    func testSpeakerIdentitiesStayScopedToEachMossPart() {
        XCTAssertEqual(LocalTranscriptSupport.speakerLabel("S01", chunk: 0, chunkCount: 1), "Hablante 1")
        XCTAssertNotEqual(
            LocalTranscriptSupport.speakerLabel("S01", chunk: 0, chunkCount: 2),
            LocalTranscriptSupport.speakerLabel("S01", chunk: 1, chunkCount: 2)
        )
    }

    func testRetranscriptionReplacesOnlySubtitlesAndPreservesSpeakerLabels() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let recording = try RecordingsStore(folder: directory).makeNewRecording()
        let originalAudio = Data([1, 2, 3, 4])
        try originalAudio.write(to: recording.audioURL)
        try "previous transcript".write(to: recording.subtitleURL, atomically: true, encoding: .utf8)
        try SRTWriter.write(segments: [
            Subtitle(start: 12.5, end: 15, text: "El proyecto termina el viernes.", speaker: "Hablante 1")
        ], to: recording.subtitleURL)
        XCTAssertEqual(try Data(contentsOf: recording.audioURL), originalAudio)
        let srt = try String(contentsOf: recording.subtitleURL, encoding: .utf8)
        XCTAssertTrue(srt.contains("00:00:12,500 --> 00:00:15,000"))
        XCTAssertTrue(srt.contains("[Hablante 1] El proyecto termina el viernes."))
        XCTAssertFalse(srt.contains("previous transcript"))
    }
}
