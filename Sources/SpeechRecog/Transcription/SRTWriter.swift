import Foundation

enum SRTWriter {
    static func write(segments: [Subtitle], to url: URL) throws {
        var output = ""
        for (index, seg) in segments.enumerated() {
            output += "\(index + 1)\n"
            output += "\(timestamp(seg.start)) --> \(timestamp(seg.end))\n"
            output += seg.text + "\n\n"
        }
        try output.write(to: url, atomically: true, encoding: .utf8)
    }

    private static func timestamp(_ seconds: TimeInterval) -> String {
        let s = max(0, seconds)
        let hours = Int(s) / 3600
        let mins = (Int(s) % 3600) / 60
        let secs = Int(s) % 60
        let millis = Int((s - floor(s)) * 1000)
        return String(format: "%02d:%02d:%02d,%03d", hours, mins, secs, millis)
    }
}
