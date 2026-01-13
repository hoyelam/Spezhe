import Foundation
import RevenueCat

public enum SubscriptionStatus: Equatable {
    case unknown
    case notSubscribed
    case subscribed
    case error(String)
}

public enum PurchaseError: Error, LocalizedError {
    case purchaseCancelled
    case purchaseFailed(String)
    case restoreFailed(String)
    case offeringsNotAvailable

    public var errorDescription: String? {
        switch self {
        case .purchaseCancelled:
            return "Purchase was cancelled"
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        case .restoreFailed(let message):
            return "Restore failed: \(message)"
        case .offeringsNotAvailable:
            return "Unable to load subscription options"
        }
    }
}

@MainActor
public final class SubscriptionService: NSObject, ObservableObject {
    public static let shared = SubscriptionService()

    // MARK: - Published Properties

    @Published public private(set) var status: SubscriptionStatus = .unknown
    @Published public private(set) var offerings: Offerings?
    @Published public private(set) var currentOffering: Offering?
    @Published public private(set) var isPurchasing = false
    @Published public private(set) var isLoadingOfferings = false
    @Published public private(set) var purchaseError: PurchaseError?

    private var isConfigured = false

    private override init() {
        super.init()
    }

    // MARK: - Configuration

    public func configure() {
        guard !isConfigured else { return }

        guard let apiKey = revenueCatAPIKey, !apiKey.isEmpty, apiKey != "YOUR_REVENUECAT_API_KEY" else {
            logWarning("RevenueCat API key missing; subscription service disabled", category: .app)
            status = .error("API key not configured")
            return
        }

        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: apiKey)

        isConfigured = true
        logInfo("RevenueCat configured successfully", category: .app)

        Purchases.shared.delegate = self

        Task {
            await refreshSubscriptionStatus()
        }
    }

    // MARK: - Subscription Status

    public func refreshSubscriptionStatus() async {
        configure()

        guard isConfigured else {
            logWarning("Cannot refresh subscription status: service not configured", category: .app)
            return
        }

        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateStatus(from: customerInfo)
            logDebug("Subscription status refreshed: \(status)", category: .app)
        } catch {
            logError("Failed to fetch subscription status: \(error.localizedDescription)", category: .app)
            status = .error(error.localizedDescription)
        }
    }

    public var isSubscribed: Bool {
        status == .subscribed
    }

    // MARK: - Offerings

    public func loadOfferings() async {
        configure()

        guard isConfigured else {
            logWarning("Cannot load offerings: service not configured", category: .app)
            purchaseError = .offeringsNotAvailable
            return
        }

        isLoadingOfferings = true
        purchaseError = nil

        do {
            let fetchedOfferings = try await Purchases.shared.offerings()
            offerings = fetchedOfferings
            currentOffering = fetchedOfferings.current

            if let current = currentOffering {
                logInfo("Loaded offering: \(current.identifier) with \(current.availablePackages.count) packages", category: .app)
            } else {
                logWarning("No current offering available", category: .app)
            }
        } catch {
            logError("Failed to load offerings: \(error.localizedDescription)", category: .app)
            purchaseError = .offeringsNotAvailable
        }

        isLoadingOfferings = false
    }

    // MARK: - Purchase

    public func purchase(package: Package) async throws {
        configure()

        guard isConfigured else {
            logWarning("Cannot purchase: service not configured", category: .app)
            throw PurchaseError.purchaseFailed("Service not configured")
        }

        isPurchasing = true
        purchaseError = nil

        logInfo("Starting purchase for package: \(package.identifier)", category: .app)

        do {
            let (_, customerInfo, userCancelled) = try await Purchases.shared.purchase(package: package)

            if userCancelled {
                logInfo("User cancelled purchase", category: .app)
                isPurchasing = false
                throw PurchaseError.purchaseCancelled
            }

            updateStatus(from: customerInfo)
            logInfo("Purchase successful for package: \(package.identifier)", category: .app)

            AnalyticsService.shared.track(.subscriptionPurchased, properties: [
                "package_id": package.identifier,
                "product_id": package.storeProduct.productIdentifier
            ])
        } catch let error as PurchaseError {
            isPurchasing = false
            throw error
        } catch {
            logError("Purchase failed: \(error.localizedDescription)", category: .app)
            purchaseError = .purchaseFailed(error.localizedDescription)
            isPurchasing = false
            throw PurchaseError.purchaseFailed(error.localizedDescription)
        }

        isPurchasing = false
    }

    // MARK: - Restore Purchases

    public func restorePurchases() async throws {
        configure()

        guard isConfigured else {
            logWarning("Cannot restore: service not configured", category: .app)
            throw PurchaseError.restoreFailed("Service not configured")
        }

        isPurchasing = true
        purchaseError = nil

        logInfo("Starting restore purchases", category: .app)

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            updateStatus(from: customerInfo)

            if isSubscribed {
                logInfo("Restore successful - subscription active", category: .app)
                AnalyticsService.shared.track(.subscriptionRestored)
            } else {
                logInfo("Restore completed - no active subscription found", category: .app)
            }
        } catch {
            logError("Restore failed: \(error.localizedDescription)", category: .app)
            purchaseError = .restoreFailed(error.localizedDescription)
            isPurchasing = false
            throw PurchaseError.restoreFailed(error.localizedDescription)
        }

        isPurchasing = false
    }

    // MARK: - Clear Error

    public func clearError() {
        purchaseError = nil
    }

    // MARK: - Private Helpers

    private var revenueCatAPIKey: String? {
        if let key = Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String {
            return key
        }
        return ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"]
    }

    private func updateStatus(from customerInfo: CustomerInfo) {
        if customerInfo.entitlements["pro"]?.isActive == true {
            status = .subscribed
        } else if !customerInfo.activeSubscriptions.isEmpty {
            status = .subscribed
        } else {
            status = .notSubscribed
        }
    }
}

// MARK: - PurchasesDelegate

extension SubscriptionService: PurchasesDelegate {
    nonisolated public func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            updateStatus(from: customerInfo)
            logInfo("Subscription status updated via delegate: \(status)", category: .app)
        }
    }
}
