import Foundation

#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif

@MainActor
public final class TrackingAuthorizationService {
    public static let shared = TrackingAuthorizationService()

    private init() {}

    public func requestIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Constants.UserDefaultsKeys.trackingAuthorizationRequested) else {
            return
        }

        defaults.set(true, forKey: Constants.UserDefaultsKeys.trackingAuthorizationRequested)

        #if canImport(AppTrackingTransparency)
        if #available(macOS 11.0, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                logInfo("Tracking authorization status: \(status.rawValue)", category: .app)
            }
        }
        #endif
    }
}
