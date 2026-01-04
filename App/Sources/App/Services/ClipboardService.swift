import AppKit
import Carbon.HIToolbox

public class ClipboardService {
    public static let shared = ClipboardService()

    private init() {}

    public func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    public func simulatePaste() -> Bool {
        guard AccessibilityManager.shared.isAccessibilityEnabled else {
            return false
        }

        let source = CGEventSource(stateID: .hidSystemState)

        let vKeyCode = CGKeyCode(kVK_ANSI_V)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
            return false
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        keyUp.post(tap: .cgAnnotatedSessionEventTap)

        return true
    }

    public func copyAndPaste(_ text: String) -> Bool {
        copyToClipboard(text)

        usleep(50000)

        return simulatePaste()
    }
}
