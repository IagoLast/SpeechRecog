import Foundation

@main
struct CoreCheck {
    static func main() async {
        var failed = 0
        failed += await checkSummarizer()
        failed += checkStore()
        if failed > 0 {
            fputs("\(failed) check(s) failed\n", stderr)
            exit(1)
        }
        print("core checks passed")
    }

    static func checkSummarizer() async -> Int {
        var failed = 0
        let english = """
        Need to email Ana tomorrow. The design review moved to Friday. I should book the room.
        """
        let summary = try? await ExtractiveSummarizer().summarize(transcript: english)
        if summary?.summary.contains("Need to email Ana tomorrow") != true {
            fputs("english summary missing first sentence: \(summary?.summary ?? "nil")\n", stderr)
            failed += 1
        }
        let items = summary?.actionItems.joined(separator: " | ") ?? ""
        if !items.contains("email Ana") || !items.contains("book the room") {
            fputs("english action items: \(items)\n", stderr)
            failed += 1
        }
        if items.contains("design review") {
            fputs("english action items included a non-task\n", stderr)
            failed += 1
        }

        let spanish = "Tengo que llamar a Luis. La reunión es el viernes. Recuérdame llevar el portátil."
        let es = try? await ExtractiveSummarizer().summarize(transcript: spanish)
        let esItems = es?.actionItems.joined(separator: " | ") ?? ""
        if !esItems.contains("llamar a Luis") || !esItems.lowercased().contains("portátil") && !esItems.lowercased().contains("portatil") {
            fputs("spanish action items: \(esItems)\n", stderr)
            failed += 1
        }
        if ExtractiveSummarizer.summary(from: "   ").isEmpty == false {
            fputs("blank summary should be empty\n", stderr)
            failed += 1
        }
        return failed
    }

    static func checkStore() -> Int {
        var failed = 0
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("speechrecog-core-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        guard let store = try? NotesStore(directory: directory) else {
            fputs("store init failed\n", stderr)
            return 1
        }
        let older = VoiceNote(
            id: UUID(),
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            duration: 12.4,
            transcript: "Hola",
            summary: "Un saludo.",
            actionItems: ["Tengo que llamar"],
            audioFilename: "older.m4a",
            summarizer: "extractive"
        )
        let newer = VoiceNote(
            id: UUID(),
            createdAt: Date(timeIntervalSince1970: 1_700_000_100),
            duration: 3,
            transcript: "Second",
            summary: "Later note.",
            actionItems: [],
            audioFilename: "newer.m4a",
            summarizer: "foundation-models"
        )
        do {
            try store.save([older, newer])
        } catch {
            fputs("save failed: \(error)\n", stderr)
            return 1
        }
        let loaded = store.load()
        if loaded.map(\.id) != [newer.id, older.id] {
            fputs("notes were not sorted newest first\n", stderr)
            failed += 1
        }
        if loaded.last != older {
            fputs("round trip changed the older note\n", stderr)
            failed += 1
        }
        let first = store.newAudioURL()
        let second = store.newAudioURL()
        if first == second || first.pathExtension != "m4a" {
            fputs("audio urls were not distinct m4a files\n", stderr)
            failed += 1
        }
        let stray = directory.appendingPathComponent("orphan.m4a")
        try? Data("audio".utf8).write(to: stray)
        try? Data("audio".utf8).write(to: store.audioURL(named: older.audioFilename))
        let orphans = store.unreferencedAudioFiles(excluding: Set(loaded.map(\.audioFilename)))
        if orphans.map(\.lastPathComponent) != ["orphan.m4a"] {
            fputs("orphan scan: \(orphans)\n", stderr)
            failed += 1
        }
        store.removeAudio(named: older.audioFilename)
        if FileManager.default.fileExists(atPath: store.audioURL(named: older.audioFilename).path) {
            fputs("audio file was not removed\n", stderr)
            failed += 1
        }
        try? Data("nope".utf8).write(to: directory.appendingPathComponent("notes.json"))
        if !store.load().isEmpty {
            fputs("corrupt index should load as empty\n", stderr)
            failed += 1
        }
        if !FileManager.default.fileExists(atPath: directory.appendingPathComponent("notes.json.bad").path) {
            fputs("corrupt index was not preserved\n", stderr)
            failed += 1
        }
        return failed
    }
}
