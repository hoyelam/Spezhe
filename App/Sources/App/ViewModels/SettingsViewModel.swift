import Foundation
import Combine

@MainActor
public class SettingsViewModel: ObservableObject {
    @Published public var selectedModelName: String
    @Published public var autoPasteEnabled: Bool
    @Published public var analyticsEnabled: Bool
    @Published public var isAccessibilityEnabled: Bool
    @Published public var soundFeedbackEnabled: Bool
    @Published public var recordingStartSound: String
    @Published public var recordingStopSound: String
    @Published public var recordingStorageLimitGB: Int

    private let settings = AppSettings.shared
    private let accessibilityManager = AccessibilityManager.shared

    public init() {
        self.selectedModelName = settings.selectedModelName
        self.autoPasteEnabled = settings.autoPasteEnabled
        self.analyticsEnabled = settings.analyticsEnabled
        self.isAccessibilityEnabled = accessibilityManager.isAccessibilityEnabled
        self.soundFeedbackEnabled = settings.soundFeedbackEnabled
        self.recordingStartSound = settings.recordingStartSound
        self.recordingStopSound = settings.recordingStopSound
        self.recordingStorageLimitGB = settings.recordingStorageLimitGB
    }

    public func saveSettings() {
        settings.selectedModelName = selectedModelName
        settings.autoPasteEnabled = autoPasteEnabled
        settings.analyticsEnabled = analyticsEnabled
        settings.soundFeedbackEnabled = soundFeedbackEnabled
        settings.recordingStartSound = recordingStartSound
        settings.recordingStopSound = recordingStopSound
        settings.recordingStorageLimitGB = recordingStorageLimitGB
    }

    public func refreshAccessibilityStatus() {
        isAccessibilityEnabled = accessibilityManager.checkAccessibility()
    }

    public func requestAccessibility() {
        accessibilityManager.requestAccessibility()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.refreshAccessibilityStatus()
        }
    }

    public func openAccessibilityPreferences() {
        accessibilityManager.openAccessibilityPreferences()
    }
}
