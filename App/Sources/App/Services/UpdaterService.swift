import Foundation
import SwiftUI
import Sparkle

/// Service that manages app updates via Sparkle
@MainActor
public final class UpdaterService: ObservableObject {
    public static let shared = UpdaterService()

    private let updaterController: SPUStandardUpdaterController

    public var updater: SPUUpdater {
        updaterController.updater
    }

    @Published public private(set) var canCheckForUpdates = false

    private init() {
        // Initialize updater controller
        // startingUpdater: true means it will automatically check for updates on launch
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        // Observe canCheckForUpdates changes
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    /// Manually trigger an update check
    public func checkForUpdates() {
        updater.checkForUpdates()
    }
}

/// SwiftUI view for the "Check for Updates..." menu item
public struct CheckForUpdatesView: View {
    @ObservedObject private var updaterService = UpdaterService.shared

    public init() {}

    public var body: some View {
        Button("Check for Updates...") {
            updaterService.checkForUpdates()
        }
        .disabled(!updaterService.canCheckForUpdates)
    }
}
