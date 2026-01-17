import Foundation
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleRecording = Self("toggleRecording")
}

extension Notification.Name {
    static let cycleProfileShortcut = Notification.Name("Spezhe.cycleProfileShortcut")
}

enum Constants {
    static let bundleIdentifier = "com.kin-yee.spezhe"
    static let appSupportDirectory = "Spezhe"
    static let legacyAppSupportDirectory = "Spetra"
    static let modelsDirectory = "Models"
    static let recordingsDirectoryName = "Recordings"
    static let databaseFileName = "spezhe.sqlite"
    static let legacyDatabaseFileName = "spetra.sqlite"

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
