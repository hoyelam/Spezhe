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

    @Published public var recordingStorageLimitGB: Int {
        didSet {
            let clamped = min(max(recordingStorageLimitGB, 1), 12)
            if clamped != recordingStorageLimitGB {
                recordingStorageLimitGB = clamped
                return
            }
            UserDefaults.standard.set(clamped, forKey: Constants.UserDefaultsKeys.recordingStorageLimitGB)
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

        self.soundFeedbackEnabled = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.soundFeedbackEnabled) as? Bool ?? Constants.Defaults.soundFeedbackEnabled
        self.recordingStartSound = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.recordingStartSound) ?? Constants.Defaults.recordingStartSound
        self.recordingStopSound = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.recordingStopSound) ?? Constants.Defaults.recordingStopSound

        let storedLimit = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.recordingStorageLimitGB) as? Int
        let initialLimit = storedLimit ?? Constants.Defaults.recordingStorageLimitGB
        let clampedLimit = min(max(initialLimit, 1), 12)
        self.recordingStorageLimitGB = clampedLimit
        if storedLimit != clampedLimit {
            UserDefaults.standard.set(clampedLimit, forKey: Constants.UserDefaultsKeys.recordingStorageLimitGB)
        }
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
