import SwiftUI
import AppKit

extension Color {
    // MARK: - Theme Colors

    /// Main background color - #FDFDFD in light mode, dark system default in dark mode
    static let appBackground = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? NSColor(red: 0.110, green: 0.110, blue: 0.110, alpha: 1.0)  // Dark mode
            : NSColor(red: 0.992, green: 0.992, blue: 0.992, alpha: 1.0)  // #FDFDFD
    }))

    /// Secondary background color - #F2EEEB in light mode, dark system default in dark mode
    static let secondaryBackground = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? NSColor(red: 0.157, green: 0.157, blue: 0.157, alpha: 1.0)  // Dark mode
            : NSColor(red: 0.949, green: 0.933, blue: 0.922, alpha: 1.0)  // #F2EEEB
    }))

    /// Main text color - #000000 in light mode, white in dark mode
    static let appText = Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            ? NSColor.white
            : NSColor.black
    }))
}
