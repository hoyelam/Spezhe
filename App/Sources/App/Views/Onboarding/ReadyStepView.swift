import SwiftUI

struct ReadyStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            VStack(spacing: 8) {
                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Spetra is ready to transcribe your voice.")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                QuickTip(
                    icon: "menubar.rectangle",
                    text: "Look for the waveform icon in your menu bar"
                )

                QuickTip(
                    icon: "keyboard",
                    text: "Press control + Space to start recording anytime"
                )

                QuickTip(
                    icon: "gear",
                    text: "Access settings from the menu bar or press Command + ,"
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
