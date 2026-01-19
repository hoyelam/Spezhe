import Foundation

public final class FeatureFlagService: ObservableObject {
    public static let shared = FeatureFlagService()

    public let profilesEnabled: Bool

    private init(
        profilesEnabled: Bool = false
    ) {
        self.profilesEnabled = profilesEnabled
    }
}
