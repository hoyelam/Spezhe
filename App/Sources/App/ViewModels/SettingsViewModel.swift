import Foundation
import Combine

@MainActor
public class SettingsViewModel: ObservableObject {
    @Published public var selectedModelName: String
    @Published public var autoPasteEnabled: Bool
    @Published public var isAccessibilityEnabled: Bool

    private let settings = AppSettings.shared
    private let accessibilityManager = AccessibilityManager.shared

    public init() {
        self.selectedModelName = settings.selectedModelName
        self.autoPasteEnabled = settings.autoPasteEnabled
        self.isAccessibilityEnabled = accessibilityManager.isAccessibilityEnabled
    }

    public func saveSettings() {
        settings.selectedModelName = selectedModelName
        settings.autoPasteEnabled = autoPasteEnabled
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
