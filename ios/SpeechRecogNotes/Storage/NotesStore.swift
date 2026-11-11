import Foundation

/// Voice notes live in Application Support as `notes.json` plus one `.m4a` per note.
/// The Mac app writes `.srt` next to call recordings; a note is a different document,
/// so this store does not reuse `RecordingsStore`.
struct NotesStore: Sendable {
    let directory: URL

    private var indexURL: URL {
        directory.appendingPathComponent("notes.json")
    }

    init(directory: URL) throws {
        self.directory = directory
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    static func make() throws -> NotesStore {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return try NotesStore(directory: base.appendingPathComponent("SpeechRecogNotes", isDirectory: true))
    }

    func load() -> [VoiceNote] {
        guard FileManager.default.fileExists(atPath: indexURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: indexURL)
            let notes = try Self.decoder.decode([VoiceNote].self, from: data)
            return notes.sorted { $0.createdAt > $1.createdAt }
        } catch {
            // Keep a corrupt index instead of letting the next save erase it silently.
            let bad = indexURL.appendingPathExtension("bad")
            try? FileManager.default.removeItem(at: bad)
            try? FileManager.default.moveItem(at: indexURL, to: bad)
            return []
        }
    }

    func save(_ notes: [VoiceNote]) throws {
        let data = try Self.encoder.encode(notes)
        try data.write(to: indexURL, options: .atomic)
    }

    func newAudioURL() -> URL {
        directory.appendingPathComponent("\(UUID().uuidString).m4a")
    }

    func audioURL(named filename: String) -> URL {
        directory.appendingPathComponent(filename)
    }

    func removeAudio(named filename: String) {
        try? FileManager.default.removeItem(at: audioURL(named: filename))
    }

    func unreferencedAudioFiles(excluding filenames: Set<String>) -> [URL] {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )) ?? []
        return files
            .filter { $0.pathExtension.lowercased() == "m4a" && !filenames.contains($0.lastPathComponent) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
