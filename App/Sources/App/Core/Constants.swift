import Foundation
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleRecording = Self("toggleRecording")
}

enum Constants {
    static let bundleIdentifier = "com.kin-yee.spetra"
    static let appSupportDirectory = "Spetra"
    static let modelsDirectory = "Models"

    enum UserDefaultsKeys {
        static let selectedModelName = "selectedModelName"
        static let autoPasteEnabled = "autoPasteEnabled"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }

    enum Defaults {
        static let modelName = "base"
        static let autoPasteEnabled = true
    }
}
