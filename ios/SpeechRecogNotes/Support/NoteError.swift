import Foundation

enum NoteError: LocalizedError {
    case microphoneDenied
    case speechDenied
    case recognizerUnavailable(String)
    case noSpeech
    case exportFailed
    case recorderFailed(String)

    var errorDescription: String? {
        switch self {
        case .microphoneDenied:
            return "Microphone access is off. Enable it in Settings → Privacy & Security → Microphone."
        case .speechDenied:
            return "Speech recognition is off. Enable it in Settings → Privacy & Security → Speech Recognition."
        case .recognizerUnavailable(let locale):
            return "Speech recognition is not available for \(locale)."
        case .noSpeech:
            return "No speech detected."
        case .exportFailed:
            return "Couldn't prepare the recording for transcription."
        case .recorderFailed(let message):
            return message
        }
    }
}
