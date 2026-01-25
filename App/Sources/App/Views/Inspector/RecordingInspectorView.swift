import SwiftUI

public struct RecordingInspectorView: View {
    let recording: Recording

    public init(recording: Recording) {
        self.recording = recording
    }

    public var body: some View {
        Form {
            Section(L10n.Inspector.detailsHeader) {
                LabeledContent(L10n.Inspector.duration) {
                    Text(formatDuration(recording.duration))
                        .monospacedDigit()
                }

                LabeledContent(L10n.Inspector.created) {
                    Text(recording.createdAt.formatted(date: .abbreviated, time: .shortened))
                }

                LabeledContent(L10n.Inspector.fileSize) {
                    Text(formatFileSize(recording.fileSize))
                }
            }

            Section(L10n.Inspector.transcriptionHeader) {
                LabeledContent(L10n.Inspector.wordCount) {
                    Text("\(recording.wordCount)")
                        .monospacedDigit()
                }

                LabeledContent(L10n.Inspector.language) {
                    Text(formatLanguage(recording.detectedLanguage))
                }
            }

            Section(L10n.Inspector.processingHeader) {
                LabeledContent(L10n.Inspector.modelUsed) {
                    Text(formatModelName(recording.modelUsed))
                }

                if let profileId = recording.profileId,
                   let profile = ProfileRepository.shared.fetch(byId: profileId) {
                    LabeledContent(L10n.Inspector.profile) {
                        Text(profile.name)
                    }
                }

                if recording.processedText != nil {
                    LabeledContent(L10n.Recording.Detail.aiProcessed) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
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
        guard let lang = language else { return L10n.Common.unknown }

        let locale = Locale(identifier: "en")
        if let displayName = locale.localizedString(forLanguageCode: lang) {
            return displayName
        }
        return lang
    }

    private func formatModelName(_ name: String) -> String {
        let modelDisplayNames: [String: String] = [
            "openai_whisper-base": "Whisper Base",
            "openai_whisper-small": "Whisper Small",
            "openai_whisper-medium": "Whisper Medium",
            "openai_whisper-large-v3": "Whisper Large V3",
            "distil-whisper_distil-large-v3": "Distil Large V3",
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
