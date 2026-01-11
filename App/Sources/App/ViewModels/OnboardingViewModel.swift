import Foundation
import AVFoundation

public enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case permissions = 1
    case shortcutTutorial = 2
    case ready = 3
}

@MainActor
public class OnboardingViewModel: ObservableObject {
    @Published public var currentStep: OnboardingStep = .welcome
    @Published public var microphonePermissionGranted = false
    @Published public var accessibilityPermissionGranted = false

    private let accessibilityManager = AccessibilityManager.shared

    public init() {
        refreshPermissionStatus()
    }

    public var isLastStep: Bool {
        currentStep == .ready
    }

    public var isFirstStep: Bool {
        currentStep == .welcome
    }

    public func nextStep() {
        guard let nextIndex = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = nextIndex
    }

    public func previousStep() {
        guard let prevIndex = OnboardingStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prevIndex
    }

    public func requestMicrophonePermission() async {
        microphonePermissionGranted = await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }

        AnalyticsService.shared.track(.permissionMicrophoneResult, properties: [
            "granted": microphonePermissionGranted,
            "source": "onboarding"
        ])
    }

    public func requestAccessibilityPermission() {
        accessibilityManager.requestAccessibility()
        // Refresh status after a delay since accessibility permission requires user action in System Preferences
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.accessibilityPermissionGranted = self?.accessibilityManager.checkAccessibility() ?? false
        }
    }

    public func refreshPermissionStatus() {
        accessibilityPermissionGranted = accessibilityManager.checkAccessibility()
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            microphonePermissionGranted = true
        default:
            microphonePermissionGranted = false
        }
    }

    public func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: Constants.UserDefaultsKeys.hasCompletedOnboarding)
        AnalyticsService.shared.track(.onboardingCompleted, properties: [
            "steps_completed": OnboardingStep.allCases.count
        ])
    }
}
