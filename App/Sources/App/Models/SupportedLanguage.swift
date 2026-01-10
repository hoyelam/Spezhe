import Foundation

public struct SupportedLanguage: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let nativeName: String?

    public init(id: String, name: String, nativeName: String? = nil) {
        self.id = id
        self.name = name
        self.nativeName = nativeName
    }

    public var displayName: String {
        if let native = nativeName {
            return "\(name) (\(native))"
        }
        return name
    }
}

extension SupportedLanguage {
    public static let autoDetect = SupportedLanguage(id: "auto", name: "Auto-detect")

    public static let all: [SupportedLanguage] = [
        autoDetect,
        SupportedLanguage(id: "en", name: "English"),
        SupportedLanguage(id: "zh", name: "Chinese (Mandarin)", nativeName: "中文"),
        SupportedLanguage(id: "yue", name: "Cantonese", nativeName: "廣東話"),
        SupportedLanguage(id: "nl", name: "Dutch", nativeName: "Nederlands"),
        SupportedLanguage(id: "fr", name: "French", nativeName: "Français"),
        SupportedLanguage(id: "de", name: "German", nativeName: "Deutsch"),
        SupportedLanguage(id: "es", name: "Spanish", nativeName: "Español"),
        SupportedLanguage(id: "it", name: "Italian", nativeName: "Italiano"),
        SupportedLanguage(id: "pt", name: "Portuguese", nativeName: "Português"),
        SupportedLanguage(id: "ru", name: "Russian", nativeName: "Русский"),
        SupportedLanguage(id: "ja", name: "Japanese", nativeName: "日本語"),
        SupportedLanguage(id: "ko", name: "Korean", nativeName: "한국어"),
        SupportedLanguage(id: "ar", name: "Arabic", nativeName: "العربية"),
        SupportedLanguage(id: "hi", name: "Hindi", nativeName: "हिन्दी"),
        SupportedLanguage(id: "pl", name: "Polish", nativeName: "Polski"),
        SupportedLanguage(id: "tr", name: "Turkish", nativeName: "Türkçe"),
        SupportedLanguage(id: "vi", name: "Vietnamese", nativeName: "Tiếng Việt"),
        SupportedLanguage(id: "th", name: "Thai", nativeName: "ไทย"),
        SupportedLanguage(id: "id", name: "Indonesian", nativeName: "Bahasa Indonesia"),
        SupportedLanguage(id: "uk", name: "Ukrainian", nativeName: "Українська"),
        SupportedLanguage(id: "cs", name: "Czech", nativeName: "Čeština"),
        SupportedLanguage(id: "sv", name: "Swedish", nativeName: "Svenska"),
        SupportedLanguage(id: "da", name: "Danish", nativeName: "Dansk"),
        SupportedLanguage(id: "fi", name: "Finnish", nativeName: "Suomi"),
        SupportedLanguage(id: "no", name: "Norwegian", nativeName: "Norsk"),
        SupportedLanguage(id: "he", name: "Hebrew", nativeName: "עברית"),
        SupportedLanguage(id: "el", name: "Greek", nativeName: "Ελληνικά"),
        SupportedLanguage(id: "hu", name: "Hungarian", nativeName: "Magyar"),
        SupportedLanguage(id: "ro", name: "Romanian", nativeName: "Română"),
    ]

    public static func find(byId id: String) -> SupportedLanguage? {
        all.first { $0.id == id }
    }
}
