import Foundation

/// Keeps timestamps in the original recording's time base, including silent gaps.
enum LocalTranscriptSupport {
    static let sampleRate = 16_000
    static let mossChunkSeconds = 30 * 60

    static func languageName(_ identifier: String?) -> String? {
        guard let identifier = identifier?.trimmingCharacters(in: .whitespacesAndNewlines),
              !identifier.isEmpty else { return nil }
        let code = identifier.replacingOccurrences(of: "_", with: "-")
            .split(separator: "-").first.map(String.init) ?? identifier
        // Qwen's prompt expects "Spanish", rather than a BCP-47 locale such as es-ES.
        return Locale(identifier: "en").localizedString(forLanguageCode: code)?.capitalized ?? code
    }

    static func subtitle(
        start: Double, end: Double, text: String, duration: Double,
        offset: Double = 0, speaker: String? = nil
    ) -> Subtitle? {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard start.isFinite, end.isFinite, duration.isFinite,
              duration > 0, !text.isEmpty, end >= start else { return nil }
        let start = max(0, start)
        let end = min(duration, max(end, start + 0.04))
        guard end > start else { return nil }
        return Subtitle(start: offset + start, end: offset + end, text: text, speaker: speaker)
    }

    static func groupWords(_ words: [Subtitle]) -> [Subtitle] {
        var subtitles: [Subtitle] = []
        var current: Subtitle?
        for word in words {
            if let previous = current,
               word.end - previous.start <= 6,
               previous.text.count + word.text.count + 1 <= 84,
               word.start - previous.end <= 0.8,
               previous.speaker == word.speaker {
                current = Subtitle(
                    start: previous.start, end: max(previous.end, word.end),
                    text: previous.text + " " + word.text, speaker: previous.speaker
                )
            } else {
                if let current { subtitles.append(current) }
                current = word
            }
            if let text = current?.text, let last = text.last, ".!?。！？".contains(last) {
                if let current { subtitles.append(current) }
                current = nil
            }
        }
        if let current { subtitles.append(current) }
        return subtitles
    }

    /// MOSS speaker IDs are only comparable within one inference call.
    static func speakerLabel(_ speaker: String, chunk: Int, chunkCount: Int) -> String {
        let label = Int(speaker.dropFirst()).map { "Hablante \($0)" } ?? speaker
        return chunkCount > 1 ? "\(label), parte \(chunk + 1)" : label
    }

    /// Merge padded VAD ranges, then split continuous speech near a quiet boundary.
    /// No samples are dropped at a split, and no overlap is transcribed twice.
    static func speechChunks(audio: [Float], ranges: [Range<Int>]) -> [Range<Int>] {
        let padding = sampleRate / 5
        let limit = 25 * sampleRate
        var merged: [Range<Int>] = []
        for range in ranges.sorted(by: { $0.lowerBound < $1.lowerBound }) {
            let start = max(0, range.lowerBound - padding)
            let end = min(audio.count, range.upperBound + padding)
            guard start < end else { continue }
            if let previous = merged.last, start - previous.upperBound <= sampleRate / 2 {
                merged[merged.count - 1] = previous.lowerBound..<max(end, previous.upperBound)
            } else {
                merged.append(start..<end)
            }
        }
        var chunks: [Range<Int>] = []
        for range in merged {
            var start = range.lowerBound
            while range.upperBound - start > limit {
                let target = start + limit
                let window = sampleRate / 10
                var boundary = target
                var minimum = Double.infinity
                for candidate in stride(from: target - 2 * sampleRate, through: target - window, by: window) {
                    let energy = audio[candidate..<(candidate + window)].reduce(0.0) { $0 + Double($1 * $1) }
                    if energy < minimum {
                        minimum = energy
                        boundary = candidate + window / 2
                    }
                }
                chunks.append(start..<boundary)
                start = boundary
            }
            if start < range.upperBound { chunks.append(start..<range.upperBound) }
        }
        return chunks
    }
}
