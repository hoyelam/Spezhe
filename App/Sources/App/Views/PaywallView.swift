import SwiftUI
import RevenueCat

public struct PaywallView: View {
    @ObservedObject private var subscriptionService = SubscriptionService.shared
    @Binding var isPresented: Bool

    @State private var selectedPackage: Package?
    @State private var showingRestoreAlert = false
    @State private var restoreAlertMessage = ""

    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    public var body: some View {
        VStack(spacing: 0) {
            closeButton

            ScrollView {
                VStack(spacing: 24) {
                    headerSection

                    if subscriptionService.isLoadingOfferings {
                        loadingView
                    } else if let error = subscriptionService.purchaseError {
                        errorView(error: error)
                    } else if let offering = subscriptionService.currentOffering {
                        packagesSection(offering: offering)
                    } else {
                        noOfferingsView
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }

            footerSection
        }
        .frame(width: 480, height: 600)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            Task {
                await subscriptionService.loadOfferings()
            }
            AnalyticsService.shared.track(.paywallViewed)
        }
        .alert("Restore Purchases", isPresented: $showingRestoreAlert) {
            Button("OK") { }
        } message: {
            Text(restoreAlertMessage)
        }
    }

    // MARK: - Close Button

    private var closeButton: some View {
        HStack {
            Spacer()
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .padding()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            Text("Spetra Pro")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Unlock the full power of voice transcription")
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            featuresGrid
        }
    }

    private var featuresGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            FeatureRow(icon: "cpu", title: "Advanced Models", description: "Access larger, more accurate Whisper models")
            FeatureRow(icon: "globe", title: "All Languages", description: "Transcribe in 99+ languages")
            FeatureRow(icon: "clock.arrow.circlepath", title: "Unlimited History", description: "Keep all your recordings forever")
            FeatureRow(icon: "sparkles", title: "AI Summaries", description: "Get smart summaries of your transcriptions")
        }
        .padding()
        .background(Color.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Packages Section

    private func packagesSection(offering: Offering) -> some View {
        VStack(spacing: 12) {
            Text("Choose Your Plan")
                .font(.headline)

            ForEach(offering.availablePackages, id: \.identifier) { package in
                PackageRowView(
                    package: package,
                    isSelected: selectedPackage?.identifier == package.identifier,
                    onSelect: {
                        selectedPackage = package
                    }
                )
            }

            subscribeButton
        }
    }

    private var subscribeButton: some View {
        Button {
            Task {
                await performPurchase()
            }
        } label: {
            HStack {
                if subscriptionService.isPurchasing {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.trailing, 4)
                }
                Text(subscriptionService.isPurchasing ? "Processing..." : "Subscribe")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(selectedPackage == nil || subscriptionService.isPurchasing)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Loading subscription options...")
                .foregroundStyle(.secondary)
        }
        .frame(height: 200)
    }

    // MARK: - Error View

    private func errorView(error: PurchaseError) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.orange)

            Text(error.localizedDescription)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                subscriptionService.clearError()
                Task {
                    await subscriptionService.loadOfferings()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    // MARK: - No Offerings View

    private var noOfferingsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.circle")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("No subscription options available")
                .foregroundStyle(.secondary)

            Button("Retry") {
                Task {
                    await subscriptionService.loadOfferings()
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(height: 200)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: 12) {
            Divider()

            HStack {
                Button("Restore Purchases") {
                    Task {
                        await performRestore()
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .disabled(subscriptionService.isPurchasing)

                Spacer()

                HStack(spacing: 16) {
                    Link("Terms", destination: URL(string: "https://spetra.app/terms")!)
                    Link("Privacy", destination: URL(string: "https://spetra.app/privacy")!)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Actions

    private func performPurchase() async {
        guard let package = selectedPackage else { return }

        do {
            try await subscriptionService.purchase(package: package)
            isPresented = false
        } catch PurchaseError.purchaseCancelled {
            // User cancelled, do nothing
        } catch {
            // Error is already set in subscriptionService.purchaseError
        }
    }

    private func performRestore() async {
        do {
            try await subscriptionService.restorePurchases()
            if subscriptionService.isSubscribed {
                restoreAlertMessage = "Your subscription has been restored!"
                showingRestoreAlert = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    isPresented = false
                }
            } else {
                restoreAlertMessage = "No active subscription found for this account."
                showingRestoreAlert = true
            }
        } catch {
            restoreAlertMessage = error.localizedDescription
            showingRestoreAlert = true
        }
    }
}

// MARK: - Supporting Views

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct PackageRowView: View {
    let package: Package
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(packageTitle)
                            .font(.headline)

                        if isBestValue {
                            Text("Best Value")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }

                    Text(priceDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.secondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var packageTitle: String {
        switch package.packageType {
        case .monthly:
            return "Monthly"
        case .annual:
            return "Yearly"
        case .weekly:
            return "Weekly"
        case .lifetime:
            return "Lifetime"
        default:
            return package.storeProduct.localizedTitle
        }
    }

    private var priceDescription: String {
        let price = package.storeProduct.localizedPriceString

        switch package.packageType {
        case .monthly:
            return "\(price)/month"
        case .annual:
            let monthlyPrice = package.storeProduct.price as Decimal / 12
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = package.storeProduct.priceFormatter?.locale
            let monthlyString = formatter.string(from: monthlyPrice as NSNumber) ?? ""
            return "\(price)/year (\(monthlyString)/month)"
        case .weekly:
            return "\(price)/week"
        case .lifetime:
            return "\(price) one-time"
        default:
            return price
        }
    }

    private var isBestValue: Bool {
        package.packageType == .annual
    }
}

#Preview {
    PaywallView(isPresented: .constant(true))
}
