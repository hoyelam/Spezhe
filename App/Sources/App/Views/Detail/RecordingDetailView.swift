import SwiftUI

public struct RecordingDetailView: View {
    let recording: Recording
    let onTitleChange: (String) -> Void
    @StateObject private var playbackViewModel: AudioPlaybackViewModel

    public init(recording: Recording, onTitleChange: @escaping (String) -> Void) {
        self.recording = recording
        self.onTitleChange = onTitleChange
        self._playbackViewModel = StateObject(wrappedValue: AudioPlaybackViewModel(recording: recording))
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
                Text(recording.transcriptionText)
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
