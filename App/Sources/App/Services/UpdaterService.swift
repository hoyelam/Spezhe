import Foundation
import Sparkle

/// Service that manages app updates via Sparkle
@MainActor
public final class UpdaterService {
    public static let shared = UpdaterService()

    private let updaterController: SPUStandardUpdaterController

    public var updater: SPUUpdater {
        updaterController.updater
    }

    private init() {
        // Initialize updater controller
        // startingUpdater: true means it will automatically check for updates on launch
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    /// Manually trigger an update check
    public func checkForUpdates() {
        updater.checkForUpdates()
    }

    /// Whether an update check can be performed right now
    public var canCheckForUpdates: Bool {
        updater.canCheckForUpdates
    }
}
