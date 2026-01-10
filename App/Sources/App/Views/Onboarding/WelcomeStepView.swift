import SwiftUI

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.tint)

            VStack(spacing: 12) {
                Text("Welcome to Spetra")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Voice transcription, simplified.")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(
                    icon: "mic.fill",
                    title: "Record Anywhere",
                    description: "Use the global shortcut to capture audio from any app"
                )

                FeatureRow(
                    icon: "text.quote",
                    title: "Instant Transcription",
                    description: "Powered by OpenAI Whisper for accurate speech-to-text"
                )

                FeatureRow(
                    icon: "doc.on.clipboard",
                    title: "Auto-Paste",
                    description: "Transcribed text is automatically copied and pasted"
                )
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)
        }
        .padding(.vertical, 32)
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.accentColor)
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    WelcomeStepView()
        .frame(width: 520, height: 400)
}
