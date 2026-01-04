import SwiftUI

public struct RecordingInspectorView: View {
    let recording: Recording

    public init(recording: Recording) {
        self.recording = recording
    }

    public var body: some View {
        Form {
            Section("Details") {
                LabeledContent("Duration") {
                    Text(formatDuration(recording.duration))
                        .monospacedDigit()
                }

                LabeledContent("Created") {
                    Text(recording.createdAt.formatted(date: .abbreviated, time: .shortened))
                }

                LabeledContent("File Size") {
                    Text(formatFileSize(recording.fileSize))
                }
            }

            Section("Transcription") {
                LabeledContent("Word Count") {
                    Text("\(recording.wordCount)")
                        .monospacedDigit()
                }

                LabeledContent("Language") {
                    Text(formatLanguage(recording.detectedLanguage))
                }
            }

            Section("Processing") {
                LabeledContent("Model Used") {
                    Text(formatModelName(recording.modelUsed))
                }
            }
        }
        .formStyle(.grouped)
        .inspectorColumnWidth(min: 200, ideal: 250, max: 300)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func formatLanguage(_ language: String?) -> String {
        guard let lang = language else { return "Unknown" }

        let locale = Locale(identifier: "en")
        if let displayName = locale.localizedString(forLanguageCode: lang) {
            return displayName
        }
        return lang
    }

    private func formatModelName(_ name: String) -> String {
        let modelDisplayNames: [String: String] = [
            "base": "Whisper Base",
            "small": "Whisper Small",
            "medium": "Whisper Medium",
            "large-v3": "Whisper Large V3",
            "distil-large-v3": "Distil Large V3"
        ]
        return modelDisplayNames[name] ?? name.capitalized
    }
}

#Preview {
    RecordingInspectorView(recording: Recording(
        id: 1,
        title: "Test Recording",
        transcriptionText: "This is a test transcription with multiple words",
        audioFileName: "test.wav",
        createdAt: Date(),
        duration: 125.5,
        detectedLanguage: "en",
        wordCount: 8,
        modelUsed: "base",
        fileSize: 2_048_000
    ))
}
