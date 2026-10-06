import Foundation

enum InterfaceLanguage: String, CaseIterable, Identifiable, Codable {
    case english = "en"
    case vietnamese = "vi"
    case simplifiedChinese = "zh-Hans"
    case japanese = "ja"
    case korean = "ko"
    case french = "fr"
    case german = "de"
    case spanish = "es"

    var id: String { rawValue }

    /// Native names stay recognizable even when the current UI language is unfamiliar.
    var nativeName: String {
        switch self {
        case .english: "English"
        case .vietnamese: "Tiếng Việt"
        case .simplifiedChinese: "简体中文"
        case .japanese: "日本語"
        case .korean: "한국어"
        case .french: "Français"
        case .german: "Deutsch"
        case .spanish: "Español"
        }
    }
}

enum L10n {
    static let defaultsKey = "interfaceLanguage"

    static var currentLanguage: InterfaceLanguage {
        InterfaceLanguage(rawValue: UserDefaults.standard.string(forKey: defaultsKey) ?? "") ?? .english
    }

    static func string(_ key: String, language: InterfaceLanguage = currentLanguage) -> String {
        guard
            let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else { return key }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
