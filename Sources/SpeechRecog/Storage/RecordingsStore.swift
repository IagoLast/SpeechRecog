import Foundation

struct Recording {
    let id: UUID
    let createdAt: Date
    let audioURL: URL
    let subtitleURL: URL
}

final class RecordingsStore {
    let folder: URL

    init() {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents")
        self.folder = base.appendingPathComponent("SpeechRecog", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    func makeNewRecording() throws -> Recording {
        let now = Date()
        let id = UUID()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        let stamp = formatter.string(from: now).replacingOccurrences(of: ":", with: "-")
        let base = folder.appendingPathComponent("recording-\(stamp)")
        return Recording(
            id: id,
            createdAt: now,
            audioURL: base.appendingPathExtension("m4a"),
            subtitleURL: base.appendingPathExtension("srt")
        )
    }
}
