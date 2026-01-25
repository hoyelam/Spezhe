import SwiftUI

struct ReadyStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            VStack(spacing: 8) {
                Text(L10n.Onboarding.Ready.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(L10n.Onboarding.Ready.subtitle)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                QuickTip(
                    icon: "menubar.rectangle",
                    text: L10n.Onboarding.Ready.menuBarTip
                )

                QuickTip(
                    icon: "keyboard",
                    text: L10n.Onboarding.Ready.shortcutTip
                )

                QuickTip(
                    icon: "gear",
                    text: L10n.Onboarding.Ready.settingsTip
                )
            }
            .padding(.horizontal, 48)
            .padding(.top, 16)
        }
        .padding(.vertical, 32)
    }
}

private struct QuickTip: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.accentColor)
                .frame(width: 28)

            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    ReadyStepView()
        .frame(width: 520, height: 400)
}
