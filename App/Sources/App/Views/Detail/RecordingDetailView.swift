import SwiftUI

public struct RecordingDetailView: View {
    let recording: Recording
    let onTitleChange: (String) -> Void
    @StateObject private var playbackViewModel: AudioPlaybackViewModel
    @State private var showOriginal = false

    public init(recording: Recording, onTitleChange: @escaping (String) -> Void) {
        self.recording = recording
        self.onTitleChange = onTitleChange
        self._playbackViewModel = StateObject(wrappedValue: AudioPlaybackViewModel(recording: recording))
    }

    private var hasProcessedText: Bool {
        recording.processedText != nil && !recording.processedText!.isEmpty
    }

    private var displayText: String {
        if showOriginal || !hasProcessedText {
            return recording.transcriptionText
        }
        return recording.processedText!
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

            // Toggle between processed and original text if processed text exists
            if hasProcessedText {
                HStack {
                    Label(showOriginal ? "Original Transcription" : "AI Processed", systemImage: showOriginal ? "doc.text" : "sparkles")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button {
                        showOriginal.toggle()
                    } label: {
                        Text(showOriginal ? "Show Processed" : "Show Original")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))

                Divider()
            }

            ScrollView {
                Text(displayText)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }

            Divider()

            AudioPlayerView(viewModel: playbackViewModel)
        }
    }
}
