import Foundation
import Combine
import AVFoundation
import AppKit

@MainActor
public class SettingsViewModel: ObservableObject {
    @Published public var selectedModelName: String
    @Published public var autoPasteEnabled: Bool
    @Published public var isMicrophonePermissionGranted: Bool
    @Published public var hasAudioInputDevice: Bool
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
        self.isMicrophonePermissionGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        self.hasAudioInputDevice = AVCaptureDevice.default(for: .audio) != nil
        self.isAccessibilityEnabled = accessibilityManager.isAccessibilityEnabled
        self.soundFeedbackEnabled = settings.soundFeedbackEnabled
        self.recordingStartSound = settings.recordingStartSound
        self.recordingStopSound = settings.recordingStopSound
        self.recordingStorageLimitGB = settings.recordingStorageLimitGB
    }

    public func saveSettings() {
        settings.selectedModelName = selectedModelName
        settings.autoPasteEnabled = autoPasteEnabled
        settings.soundFeedbackEnabled = soundFeedbackEnabled
        settings.recordingStartSound = recordingStartSound
        settings.recordingStopSound = recordingStopSound
        settings.recordingStorageLimitGB = recordingStorageLimitGB
    }

    public func refreshAccessibilityStatus() {
        isAccessibilityEnabled = accessibilityManager.checkAccessibility()
    }

    public func refreshPermissionStatus() {
        isMicrophonePermissionGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        hasAudioInputDevice = AVCaptureDevice.default(for: .audio) != nil
        refreshAccessibilityStatus()
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

    public func openMicrophonePreferences() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") else { return }
        NSWorkspace.shared.open(url)
    }

    public func openSoundInputPreferences() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.sound?input") else { return }
        NSWorkspace.shared.open(url)
    }
}
