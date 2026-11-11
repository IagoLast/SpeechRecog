import Foundation

/// Summary and action items with no model: the first sentences, plus sentences
/// that look like tasks in English or Spanish. Used when Apple Intelligence is off.
struct ExtractiveSummarizer: NoteSummarizer {
    var name: String { "extractive" }

    func summarize(transcript: String) async throws -> NoteSummary {
        NoteSummary(
            summary: Self.summary(from: transcript),
            actionItems: Self.actionItems(from: transcript)
        )
    }

    static func summary(from transcript: String) -> String {
        let parts = sentences(in: transcript)
        let text: String
        if parts.isEmpty {
            text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            text = parts.prefix(2).joined(separator: " ")
        }
        guard text.count > 500 else { return text }
        let end = text.index(text.startIndex, offsetBy: 500)
        return text[..<end].trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }

    static func actionItems(from transcript: String) -> [String] {
        var seen = Set<String>()
        var items: [String] = []
        for sentence in sentences(in: transcript) {
            let key = sentence.lowercased()
            guard seen.insert(key).inserted, isAction(sentence) else { continue }
            items.append(sentence)
            if items.count == 8 { break }
        }
        return items
    }

    /// Splits on newlines and on . ! ? plus the fullwidth equivalents.
    /// This is the same function on device and in the Linux check. It is not
    /// locale-aware sentence detection, which is enough for short voice notes.
    static func sentences(in text: String) -> [String] {
        var result: [String] = []
        var current = ""
        let endings: Set<Character> = [".", "!", "?", "。", "！", "？"]
        func flush() {
            let stripped = current
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "-•* "))
            if !stripped.isEmpty { result.append(stripped) }
            current = ""
        }
        for character in text {
            if character == "\n" || character == "\r" {
                flush()
                continue
            }
            current.append(character)
            if endings.contains(character) { flush() }
        }
        flush()
        return result
    }

    private static let actionPhrases = [
        "need to", "have to", "remember to", "don't forget", "do not forget",
        "remind me", "action item", "to-do", "todo:", "i should", "we should",
        "i'll ", "i will ", "we will ", "follow up",
        "tengo que", "tenemos que", "hay que", "debo ", "debemos ",
        "recuérdame", "recuerdame", "no olvides", "no olvidar", "pendiente:", "tarea:"
    ]

    private static func isAction(_ sentence: String) -> Bool {
        let lower = sentence.lowercased()
        return actionPhrases.contains { lower.contains($0) }
    }
}
