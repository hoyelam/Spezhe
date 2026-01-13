import Foundation
import Mixpanel

public enum AnalyticsEvent: String {
    case appLaunched = "app_launched"
    case onboardingCompleted = "onboarding_completed"
    case permissionMicrophoneResult = "permission_microphone_result"
    case recordingStarted = "recording_started"
    case recordingStopped = "recording_stopped"
    case recordingCancelled = "recording_cancelled"
    case transcriptionStarted = "transcription_started"
    case transcriptionCompleted = "transcription_completed"
    case transcriptionFailed = "transcription_failed"
    case modelDownloadStarted = "model_download_started"
    case modelDownloadCompleted = "model_download_completed"
    case modelDownloadFailed = "model_download_failed"
    case summaryGenerated = "summary_generated"
    case paywallViewed = "paywall_viewed"
    case subscriptionPurchased = "subscription_purchased"
    case subscriptionRestored = "subscription_restored"
}

@MainActor
public final class AnalyticsService {
    public static let shared = AnalyticsService()

    private let settings = AppSettings.shared
    private var instance: MixpanelInstance?
    private var isConfigured = false

    private init() {}

    public func configure() {
        guard !isConfigured else { return }

        guard let token = mixpanelToken, !token.isEmpty, token != "YOUR_MIXPANEL_TOKEN" else {
            logWarning("Mixpanel token missing; analytics disabled", category: .app)
            return
        }

        let options = MixpanelOptions(
            token: token,
            flushInterval: 60,
            instanceName: "main",
            trackAutomaticEvents: true,
            optOutTrackingByDefault: false,
            useUniqueDistinctId: false,
            superProperties: baseSuperProperties(),
            serverURL: "https://api-eu.mixpanel.com",
            useGzipCompression: true
        )
        instance = Mixpanel.initialize(options: options)

        instance?.identify(distinctId: distinctId)
        isConfigured = true
        setEnabled(settings.analyticsEnabled)
    }

    public func setEnabled(_ enabled: Bool) {
        configure()
        guard let instance else { return }

        if enabled {
            instance.optInTracking()
        } else {
            instance.optOutTracking()
        }
    }

    public func track(_ event: AnalyticsEvent, properties: [String: Any] = [:]) {
        configure()
        guard settings.analyticsEnabled else { return }
        guard let instance else { return }

        let sanitized = sanitize(properties)
        instance.track(event: event.rawValue, properties: sanitized)
    }

    private var mixpanelToken: String? {
        if let token = Bundle.main.object(forInfoDictionaryKey: "MixpanelToken") as? String {
            return token
        }
        return ProcessInfo.processInfo.environment["MIXPANEL_TOKEN"]
    }

    private var distinctId: String {
        let defaults = UserDefaults.standard
        if let existing = defaults.string(forKey: Constants.UserDefaultsKeys.analyticsDistinctId) {
            return existing
        }

        let newId = UUID().uuidString
        defaults.set(newId, forKey: Constants.UserDefaultsKeys.analyticsDistinctId)
        return newId
    }

    private func baseSuperProperties() -> Properties {
        [
            "app_version": appVersion,
            "build": appBuild,
            "os_version": ProcessInfo.processInfo.operatingSystemVersionString,
            "locale": Locale.current.identifier
        ]
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
    }

    private var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
    }

    private func sanitize(_ properties: [String: Any]) -> Properties {
        var sanitized: Properties = [:]
        sanitized.reserveCapacity(properties.count)

        for (key, value) in properties {
            if let mixpanelValue = value as? MixpanelType {
                sanitized[key] = mixpanelValue
            }
        }

        return sanitized
    }
}
