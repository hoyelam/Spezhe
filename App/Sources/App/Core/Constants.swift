import Foundation
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleRecording = Self("toggleRecording")
}

extension Notification.Name {
    static let cycleProfileShortcut = Notification.Name("Spetra.cycleProfileShortcut")
}

enum Constants {
    static let bundleIdentifier = "com.kin-yee.spetra"
    static let appSupportDirectory = "Spetra"
    static let modelsDirectory = "Models"

    enum UserDefaultsKeys {
        static let selectedModelName = "selectedModelName"
        static let autoPasteEnabled = "autoPasteEnabled"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let activeProfileId = "activeProfileId"
        static let analyticsEnabled = "analyticsEnabled"
        static let analyticsDistinctId = "analyticsDistinctId"
        static let trackingAuthorizationRequested = "trackingAuthorizationRequested"
        static let soundFeedbackEnabled = "soundFeedbackEnabled"
        static let recordingStartSound = "recordingStartSound"
        static let recordingStopSound = "recordingStopSound"
    }

    enum Defaults {
        static let modelName = "openai_whisper-base"
        static let autoPasteEnabled = true
        static let analyticsEnabled = true
        static let soundFeedbackEnabled = true
        static let recordingStartSound = "Pop"
        static let recordingStopSound = "Tink"
    }
}
