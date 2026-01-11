import Foundation

@MainActor
public class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    @Published public var selectedModelName: String {
        didSet {
            let normalized = Self.normalizeModelName(selectedModelName)
            if normalized != selectedModelName {
                selectedModelName = normalized
                return
            }
            UserDefaults.standard.set(normalized, forKey: Constants.UserDefaultsKeys.selectedModelName)
        }
    }

    @Published public var autoPasteEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoPasteEnabled, forKey: Constants.UserDefaultsKeys.autoPasteEnabled)
        }
    }

    @Published public var activeProfileId: Int64? {
        didSet {
            if let id = activeProfileId {
                UserDefaults.standard.set(id, forKey: Constants.UserDefaultsKeys.activeProfileId)
            } else {
                UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.activeProfileId)
            }
        }
    }

    @Published public var analyticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(analyticsEnabled, forKey: Constants.UserDefaultsKeys.analyticsEnabled)
        }
    }

    private init() {
        let storedModelName = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.selectedModelName)
        let normalizedModelName = Self.normalizeModelName(storedModelName)
        self.selectedModelName = normalizedModelName
        if storedModelName != normalizedModelName {
            UserDefaults.standard.set(normalizedModelName, forKey: Constants.UserDefaultsKeys.selectedModelName)
        }
        self.autoPasteEnabled = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.autoPasteEnabled) as? Bool ?? Constants.Defaults.autoPasteEnabled

        if let storedId = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.activeProfileId) as? Int64 {
            self.activeProfileId = storedId
        } else {
            self.activeProfileId = nil
        }

        self.analyticsEnabled = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.analyticsEnabled) as? Bool ?? Constants.Defaults.analyticsEnabled
    }

    public var selectedModel: WhisperModel {
        WhisperModel.availableModels.first { $0.name == selectedModelName } ?? WhisperModel.defaultModel
    }

    public var activeProfile: TranscriptionProfile? {
        guard let id = activeProfileId else { return nil }
        return ProfileRepository.shared.fetch(byId: id)
    }

    private static func normalizeModelName(_ name: String?) -> String {
        let fallback = Constants.Defaults.modelName
        guard let name, !name.isEmpty else { return fallback }

        let legacyMap: [String: String] = [
            "base": "openai_whisper-base",
            "small": "openai_whisper-small",
            "medium": "openai_whisper-medium",
            "large-v3": "openai_whisper-large-v3",
            "distil-large-v3": "distil-whisper_distil-large-v3"
        ]
        if let mapped = legacyMap[name] {
            return mapped
        }

        if WhisperModel.model(named: name) != nil {
            return name
        }

        return fallback
    }
}
