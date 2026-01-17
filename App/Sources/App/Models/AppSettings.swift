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

    @Published public var soundFeedbackEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundFeedbackEnabled, forKey: Constants.UserDefaultsKeys.soundFeedbackEnabled)
        }
    }

    @Published public var recordingStartSound: String {
        didSet {
            UserDefaults.standard.set(recordingStartSound, forKey: Constants.UserDefaultsKeys.recordingStartSound)
        }
    }

    @Published public var recordingStopSound: String {
        didSet {
            UserDefaults.standard.set(recordingStopSound, forKey: Constants.UserDefaultsKeys.recordingStopSound)
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

        self.soundFeedbackEnabled = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.soundFeedbackEnabled) as? Bool ?? Constants.Defaults.soundFeedbackEnabled
        self.recordingStartSound = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.recordingStartSound) ?? Constants.Defaults.recordingStartSound
        self.recordingStopSound = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.recordingStopSound) ?? Constants.Defaults.recordingStopSound
    }

    public var selectedModel: WhisperModel {
        WhisperModel.availableModels.first { $0.name == selectedModelName } ?? WhisperModel.defaultModel
    }

    public var effectiveModelName: String {
        resolvedModelName(for: activeProfile)
    }

    public var effectiveModel: WhisperModel {
        WhisperModel.availableModels.first { $0.name == effectiveModelName } ?? WhisperModel.defaultModel
    }

    public var activeProfile: TranscriptionProfile? {
        guard SubscriptionService.shared.canUseProfiles else { return nil }
        guard let id = activeProfileId else { return nil }
        return ProfileRepository.shared.fetch(byId: id)
    }

    public func resolvedModelName(for profile: TranscriptionProfile?) -> String {
        guard let overrideName = Self.canonicalModelName(profile?.modelName) else {
            return selectedModelName
        }

        guard ModelManagerService.shared.isModelDownloaded(overrideName) else {
            return selectedModelName
        }

        return overrideName
    }

    private static let legacyModelNameMap: [String: String] = [
        "base": "openai_whisper-base",
        "small": "openai_whisper-small",
        "medium": "openai_whisper-medium",
        "large-v3": "openai_whisper-large-v3",
        "distil-large-v3": "distil-whisper_distil-large-v3"
    ]

    private static func canonicalModelName(_ name: String?) -> String? {
        guard let name, !name.isEmpty else { return nil }
        let normalized = legacyModelNameMap[name] ?? name
        guard WhisperModel.model(named: normalized) != nil else { return nil }
        return normalized
    }

    private static func normalizeModelName(_ name: String?) -> String {
        canonicalModelName(name) ?? Constants.Defaults.modelName
    }
}
