import Foundation
import Combine

enum TranscriptionBackend: String, CaseIterable, Identifiable {
    case whisperKit
    case appleSpeech
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .whisperKit: return "WhisperKit (on-device)"
        case .appleSpeech: return "Apple Speech (SFSpeechRecognizer)"
        }
    }
}

/// Available WhisperKit model identifiers. The list is intentionally short:
/// larger models give better quality at the cost of disk + RAM + CPU/GPU time.
/// See https://github.com/argmaxinc/WhisperKit for the full catalog.
enum WhisperModel: String, CaseIterable, Identifiable {
    case tiny = "openai_whisper-tiny"
    case base = "openai_whisper-base"
    case small = "openai_whisper-small"
    case mediumQ4 = "openai_whisper-medium.en"
    case large = "openai_whisper-large-v3"
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tiny: return "Tiny (~75 MB, rápido)"
        case .base: return "Base (~145 MB)"
        case .small: return "Small (~465 MB)"
        case .mediumQ4: return "Medium EN (~1.5 GB)"
        case .large: return "Large v3 (~3 GB, mejor calidad)"
        }
    }
}

final class Settings: ObservableObject {
    private enum Key {
        static let backend = "transcriptionBackend"
        static let whisperModel = "whisperModel"
        static let language = "language"
        static let includeMicrophone = "includeMicrophone"
        static let recordingsFolder = "recordingsFolder"
    }

    private let defaults = UserDefaults.standard

    @Published var transcriptionBackend: TranscriptionBackend {
        didSet { defaults.set(transcriptionBackend.rawValue, forKey: Key.backend) }
    }

    @Published var whisperModel: String {
        didSet { defaults.set(whisperModel, forKey: Key.whisperModel) }
    }

    /// BCP-47 language code (e.g. "es", "en-US"); nil means auto-detect.
    @Published var language: String? {
        didSet { defaults.set(language, forKey: Key.language) }
    }

    @Published var includeMicrophone: Bool {
        didSet { defaults.set(includeMicrophone, forKey: Key.includeMicrophone) }
    }

    @Published var recordingsFolder: URL {
        didSet {
            defaults.set(recordingsFolder.path, forKey: Key.recordingsFolder)
            try? FileManager.default.createDirectory(at: recordingsFolder, withIntermediateDirectories: true)
        }
    }

    static var defaultRecordingsFolder: URL {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Documents")
        return base.appendingPathComponent("SpeechRecog", isDirectory: true)
    }

    init() {
        self.transcriptionBackend = TranscriptionBackend(
            rawValue: UserDefaults.standard.string(forKey: Key.backend) ?? ""
        ) ?? .whisperKit
        self.whisperModel = UserDefaults.standard.string(forKey: Key.whisperModel) ?? WhisperModel.base.rawValue
        self.language = UserDefaults.standard.string(forKey: Key.language)

        if UserDefaults.standard.object(forKey: Key.includeMicrophone) != nil {
            self.includeMicrophone = UserDefaults.standard.bool(forKey: Key.includeMicrophone)
        } else {
            self.includeMicrophone = true
        }

        if let path = UserDefaults.standard.string(forKey: Key.recordingsFolder), !path.isEmpty {
            self.recordingsFolder = URL(fileURLWithPath: path, isDirectory: true)
        } else {
            self.recordingsFolder = Settings.defaultRecordingsFolder
        }
        try? FileManager.default.createDirectory(at: self.recordingsFolder, withIntermediateDirectories: true)
    }
}
