import Foundation

@MainActor
@Observable
final class AppSettings {
    static let shared = AppSettings()

    private static let languageKey = "speechrecog.notes.language"

    /// BCP-47 tag. Empty string means the system locale, matching the Mac app's
    /// Apple Speech behavior when the language field is left blank.
    var languageCode: String {
        didSet { UserDefaults.standard.set(languageCode, forKey: Self.languageKey) }
    }

    private init() {
        languageCode = UserDefaults.standard.string(forKey: Self.languageKey) ?? ""
    }

    var transcriptionLocale: Locale {
        if languageCode.isEmpty { return .current }
        return Locale(identifier: languageCode)
    }
}
