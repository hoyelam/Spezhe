import Foundation

@MainActor
public class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    @Published public var selectedModelName: String {
        didSet {
            UserDefaults.standard.set(selectedModelName, forKey: Constants.UserDefaultsKeys.selectedModelName)
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

    private init() {
        self.selectedModelName = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.selectedModelName) ?? Constants.Defaults.modelName
        self.autoPasteEnabled = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.autoPasteEnabled) as? Bool ?? Constants.Defaults.autoPasteEnabled

        if let storedId = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.activeProfileId) as? Int64 {
            self.activeProfileId = storedId
        } else {
            self.activeProfileId = nil
        }
    }

    public var selectedModel: WhisperModel {
        WhisperModel.availableModels.first { $0.name == selectedModelName } ?? WhisperModel.defaultModel
    }

    public var activeProfile: TranscriptionProfile? {
        guard let id = activeProfileId else { return nil }
        return ProfileRepository.shared.fetch(byId: id)
    }
}
