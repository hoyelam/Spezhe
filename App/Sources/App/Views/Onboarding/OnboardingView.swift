import SwiftUI

public struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var isPresented: Bool

    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    public var body: some View {
        VStack(spacing: 0) {
            progressIndicator
                .padding(.top, 24)
                .padding(.bottom, 16)

            stepContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            navigationButtons
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
        }
        .frame(width: 520, height: 480)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            viewModel.refreshPermissionStatus()
        }
    }

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                Circle()
                    .fill(step.rawValue <= viewModel.currentStep.rawValue ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .welcome:
            WelcomeStepView()
        case .permissions:
            PermissionsStepView(viewModel: viewModel)
        case .shortcutTutorial:
            ShortcutTutorialStepView()
        case .ready:
            ReadyStepView()
        }
    }

    private var navigationButtons: some View {
        HStack {
            if !viewModel.isLastStep {
                Button(L10n.Onboarding.skip) {
                    Task {
                        await viewModel.requestMicrophonePermission()
                    }
                    viewModel.completeOnboarding()
                    isPresented = false
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }

            Spacer()

            if !viewModel.isFirstStep {
                Button(L10n.Onboarding.back) {
                    viewModel.previousStep()
                }
                .buttonStyle(.bordered)
            }

            Button(viewModel.isLastStep ? L10n.Onboarding.getStarted : L10n.Onboarding.continue) {
                if viewModel.isLastStep {
                    viewModel.completeOnboarding()
                    isPresented = false
                } else {
                    viewModel.nextStep()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
