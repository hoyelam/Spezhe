import Foundation

public enum RecordingTriggerSource: String {
    case keyboardShortcut = "keyboard_shortcut"
    case mainWindowButton = "main_window_button"
    case sidebarButton = "sidebar_button"
    case popupButton = "popup_button"
    case unknown = "unknown"
}
