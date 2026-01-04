import AppKit
@preconcurrency import ApplicationServices

@MainActor
public class AccessibilityManager: ObservableObject {
    public static let shared = AccessibilityManager()

    @Published public private(set) var isAccessibilityEnabled: Bool

    private init() {
        self.isAccessibilityEnabled = AXIsProcessTrusted()
    }

    public func checkAccessibility() -> Bool {
        isAccessibilityEnabled = AXIsProcessTrusted()
        return isAccessibilityEnabled
    }

    public func requestAccessibility() {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.isAccessibilityEnabled = AXIsProcessTrusted()
        }
    }

    public func openAccessibilityPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
