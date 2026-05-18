import Foundation

struct Recording {
    let id: UUID
    let createdAt: Date
    let audioURL: URL
    let subtitleURL: URL
}

final class RecordingsStore {
    var folder: URL

    init(folder: URL) {
        self.folder = folder
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    }

    func listRecordings() -> [Recording] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: folder, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles
        ) else { return [] }

        let m4aFiles = files.filter { $0.pathExtension == "m4a" }
        return m4aFiles.compactMap { audioURL -> Recording? in
            let creationDate = (try? audioURL.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast
            let baseName = audioURL.deletingPathExtension().lastPathComponent
            let subtitleURL = folder.appendingPathComponent(baseName).appendingPathExtension("srt")
            return Recording(
                id: UUID(),
                createdAt: creationDate,
                audioURL: audioURL,
                subtitleURL: subtitleURL
            )
        }
        .sorted { $0.createdAt > $1.createdAt }
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
