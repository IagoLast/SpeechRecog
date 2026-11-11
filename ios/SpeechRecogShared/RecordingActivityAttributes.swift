import ActivityKit
import Foundation

/// Lock Screen / Dynamic Island state for an in-progress voice note.
/// Shared by the app and the widget extension so ActivityKit sees one type.
public struct RecordingActivityAttributes: ActivityAttributes, Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
        public var phase: Phase
        public var startedAt: Date
        public var detail: String

        public init(phase: Phase, startedAt: Date, detail: String) {
            self.phase = phase
            self.startedAt = startedAt
            self.detail = detail
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(phase, forKey: .phase)
            try container.encode(startedAt, forKey: .startedAt)
            try container.encode(detail, forKey: .detail)
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            phase = try container.decode(Phase.self, forKey: .phase)
            startedAt = try container.decode(Date.self, forKey: .startedAt)
            detail = try container.decode(String.self, forKey: .detail)
        }

        private enum CodingKeys: String, CodingKey {
            case phase
            case startedAt
            case detail
        }
    }

    public enum Phase: String, Codable, Hashable, Sendable {
        case recording
        case transcribing
        case summarizing
        case done
    }

    public var noteID: String

    public init(noteID: String) {
        self.noteID = noteID
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(noteID, forKey: .noteID)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        noteID = try container.decode(String.self, forKey: .noteID)
    }

    private enum CodingKeys: String, CodingKey {
        case noteID
    }
}
