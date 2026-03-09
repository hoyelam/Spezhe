import SwiftUI

public struct RecordingDetailView: View {
    let recording: Recording
    let onTitleChange: (String) -> Void
    private let forceUnavailable: Bool
    @StateObject private var playbackViewModel: AudioPlaybackViewModel

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
