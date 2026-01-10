import SwiftUI

public struct RecordingRowView: View {
    let recording: Recording

    private let maxTitleCharacters = 50

    public init(recording: Recording) {
        self.recording = recording
    }

    private var displayTitle: String {
        // Priority: oneLiner > truncated transcription > fallback
        if let oneLiner = recording.oneLiner, !oneLiner.isEmpty {
            return oneLiner
        }
        // Fallback to truncated transcription
        let transcription = recording.transcriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        if transcription.isEmpty {
            return "No transcription"
        }
        if transcription.count <= maxTitleCharacters {
            return transcription
        }
        let truncated = String(transcription.prefix(maxTitleCharacters))
        return truncated + "..."
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(displayTitle)
                .font(.headline)
                .lineLimit(2)

            HStack {
                Text(recording.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if recording.profileId != nil {
                    Label("Profile", systemImage: "person.crop.rectangle.stack.fill")
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                        .labelStyle(.iconOnly)
                }

                if recording.processedText != nil {
                    Label("AI", systemImage: "sparkles")
                        .font(.caption2)
                        .foregroundColor(.purple)
                        .labelStyle(.iconOnly)
                }

                Spacer()
                Text(formatDuration(recording.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    VStack(spacing: 16) {
        RecordingRowView(recording: Recording(
            id: 1,
            title: "Test Recording",
            transcriptionText: "This is a test transcription that demonstrates the preview feature",
            audioFileName: "test.wav",
            createdAt: Date(),
            duration: 125,
            detectedLanguage: "en",
            wordCount: 5,
            modelUsed: "base",
            fileSize: 1024
        ))

        RecordingRowView(recording: Recording(
            id: 2,
            title: "Empty Recording",
            transcriptionText: "",
            audioFileName: "test2.wav",
            createdAt: Date(),
            duration: 60,
            detectedLanguage: nil,
            wordCount: 0,
            modelUsed: "base",
            fileSize: 512
        ))
    }
    .padding()
}
