import Foundation

public final class FeatureFlagService: ObservableObject {
    public static let shared = FeatureFlagService()

    public let profilesEnabled: Bool
    public let subscriptionPaywallEnabled: Bool

    private init(
        profilesEnabled: Bool = false,
        subscriptionPaywallEnabled: Bool = false
    ) {
        self.profilesEnabled = profilesEnabled
        self.subscriptionPaywallEnabled = subscriptionPaywallEnabled
    }
}
