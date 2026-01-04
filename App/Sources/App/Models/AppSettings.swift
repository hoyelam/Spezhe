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

    private init() {
        self.selectedModelName = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.selectedModelName) ?? Constants.Defaults.modelName
        self.autoPasteEnabled = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.autoPasteEnabled) as? Bool ?? Constants.Defaults.autoPasteEnabled
    }

    public var selectedModel: WhisperModel {
        WhisperModel.availableModels.first { $0.name == selectedModelName } ?? WhisperModel.defaultModel
    }
}
