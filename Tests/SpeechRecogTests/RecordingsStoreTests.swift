import XCTest
@testable import SpeechRecog

final class RecordingsStoreTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.resolvingSymlinksInPath().appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: directory)
    }

    func testRapidRecordingsHaveDistinctAudioAndSubtitlePaths() throws {
        let store = RecordingsStore(folder: directory.appendingPathComponent("recordings"))
        let recordings = try (0..<100).map { _ in try store.makeNewRecording() }
        XCTAssertEqual(Set(recordings.map(\.audioURL)).count, 100)
        XCTAssertEqual(Set(recordings.map(\.subtitleURL)).count, 100)
        XCTAssertTrue(FileManager.default.fileExists(atPath: store.folder.path))
        for recording in recordings {
            XCTAssertEqual(recording.audioURL.deletingPathExtension(), recording.subtitleURL.deletingPathExtension())
        }
    }

    func testInvalidFolderThrowsBeforeRecordingStarts() throws {
        let file = directory.appendingPathComponent("file")
        try Data().write(to: file)
        let store = RecordingsStore(folder: file.appendingPathComponent("recordings"))
        XCTAssertThrowsError(try store.makeNewRecording())
    }

    func testListingFindsExistingAndNewRecordingsWithoutIncludingSubtitles() throws {
        let store = RecordingsStore(folder: directory)
        let newRecording = try store.makeNewRecording()
        let legacyURL = directory.appendingPathComponent("recording-2026-05-18T12-00-00Z.m4a")
        for url in [newRecording.audioURL, newRecording.subtitleURL, legacyURL] {
            try Data().write(to: url)
        }
        XCTAssertEqual(
            Set(store.listRecordings().map { $0.audioURL.lastPathComponent }),
            [newRecording.audioURL.lastPathComponent, legacyURL.lastPathComponent]
        )
    }
}
