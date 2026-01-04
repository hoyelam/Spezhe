import SwiftUI

public struct RecordingRowView: View {
    let recording: Recording

    public init(recording: Recording) {
        self.recording = recording
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(recording.title)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                if !recording.transcriptionText.isEmpty {
                    Image(systemName: "text.quote")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }

            HStack {
                Text(recording.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
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
    RecordingRowView(recording: Recording(
        id: 1,
        title: "Test Recording",
        transcriptionText: "This is a test transcription",
        audioFileName: "test.wav",
        createdAt: Date(),
        duration: 125,
        detectedLanguage: "en",
        wordCount: 5,
        modelUsed: "base",
        fileSize: 1024
    ))
    .padding()
}
