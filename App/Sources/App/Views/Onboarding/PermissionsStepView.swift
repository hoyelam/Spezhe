import SwiftUI

struct PermissionsStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            VStack(spacing: 8) {
                Text(L10n.Onboarding.Permissions.title)
                    .font(.title)
                    .fontWeight(.bold)

                Text(L10n.Onboarding.Permissions.subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 16) {
                PermissionRow(
                    icon: "mic.fill",
                    title: L10n.Onboarding.Permissions.microphoneTitle,
                    description: L10n.Onboarding.Permissions.microphoneDescription,
                    isGranted: viewModel.microphonePermissionGranted,
                    isRequired: true,
                    onRequest: {
                        Task {
                            await viewModel.requestMicrophonePermission()
                        }
                    }
                )

                PermissionRow(
                    icon: "accessibility",
                    title: L10n.Onboarding.Permissions.accessibilityTitle,
                    description: L10n.Onboarding.Permissions.accessibilityDescription,
                    isGranted: viewModel.accessibilityPermissionGranted,
                    isRequired: false,
                    onRequest: {
                        viewModel.requestAccessibilityPermission()
                    }
                )
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)
        }
        .padding(.vertical, 32)
        .onAppear {
            viewModel.refreshPermissionStatus()
        }
    }
}

private struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let isRequired: Bool
    let onRequest: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(isGranted ? .green : .secondary)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                    if isRequired {
                        Text(L10n.Common.required)
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 20))
            } else {
                Button(L10n.Common.grant) {
                    onRequest()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

#Preview {
    PermissionsStepView(viewModel: OnboardingViewModel())
        .frame(width: 520, height: 400)
}
