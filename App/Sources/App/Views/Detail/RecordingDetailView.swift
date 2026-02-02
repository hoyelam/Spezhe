import SwiftUI

public struct RecordingDetailView: View {
    let recording: Recording
    let onTitleChange: (String) -> Void
    private let forceUnavailable: Bool
    @StateObject private var playbackViewModel: AudioPlaybackViewModel
    @EnvironmentObject private var recordingViewModel: RecordingViewModel
    @State private var isRetryingCustomPrompt = false
    @State private var didFailRetry = false

    public init(
        recording: Recording,
        onTitleChange: @escaping (String) -> Void,
        forceUnavailable: Bool = false
    ) {
        self.recording = recording
        self.onTitleChange = onTitleChange
        self.forceUnavailable = forceUnavailable
        self._playbackViewModel = StateObject(
            wrappedValue: AudioPlaybackViewModel(recording: recording, forceUnavailable: forceUnavailable)
        )
    }

    private var hasProcessedText: Bool {
        recording.processedText != nil && !recording.processedText!.isEmpty
    }

    private var customPrompt: String? {
        guard let profileId = recording.profileId,
              let profile = ProfileRepository.shared.fetch(byId: profileId) else {
            return nil
        }
        let prompt = profile.customPrompt?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (prompt?.isEmpty ?? true) ? nil : prompt
    }

    private var shouldShowRetry: Bool {
        !hasProcessedText && customPrompt != nil
    }

    public var body: some View {
        VStack(spacing: 0) {
            RecordingHeaderView(recording: recording, onTitleChange: onTitleChange)

            Divider()

            // Summary banner (if AI summary is available)
            if let summary = recording.summary, !summary.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.accentColor)
                    Text(summary)
                        .font(.subheadline)
                    Spacer()
                }
                .padding()
                .background(Color.accentColor.opacity(0.08))

                Divider()
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TranscriptionSection(
                        title: "Original Transcription",
                        systemImage: "doc.text",
                        text: recording.transcriptionText
                    )

                    if shouldShowRetry {
                        Divider()

                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "sparkles")
                                .foregroundColor(.accentColor)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(L10n.Recording.Detail.customPromptFailedTitle)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                Text(L10n.Recording.Detail.customPromptFailedSubtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if didFailRetry {
                                    Text(L10n.Recording.Detail.customPromptRetryFailedHint)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Button {
                                guard let customPrompt else { return }
                                didFailRetry = false
                                isRetryingCustomPrompt = true
                                Task {
                                    let success = await recordingViewModel.retryCustomPrompt(
                                        for: recording,
                                        customPrompt: customPrompt
                                    )
                                    isRetryingCustomPrompt = false
                                    didFailRetry = !success
                                }
                            } label: {
                                if isRetryingCustomPrompt {
                                    ProgressView()
                                } else {
                                    Text(L10n.Recording.Detail.retryCustomPrompt)
                                }
                            }
                            .disabled(isRetryingCustomPrompt)
                        }
                        .padding(12)
                        .background(Color.accentColor.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    if hasProcessedText, let processedText = recording.processedText {
                        Divider()

                        TranscriptionSection(
                            title: "AI Processed",
                            systemImage: "sparkles",
                            text: processedText
                        )
                    }
                }
                .padding()
            }

            Divider()

            if !playbackViewModel.isAudioAvailable {
                Text("Audio unavailable")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }

            AudioPlayerView(viewModel: playbackViewModel, isEnabled: playbackViewModel.isAudioAvailable)
        }
    }
}

private struct TranscriptionSection: View {
    let title: String
    let systemImage: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(text)
                .font(.body)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
