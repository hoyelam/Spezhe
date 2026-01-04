import SwiftUI

public struct AudioPlayerView: View {
    @ObservedObject var viewModel: AudioPlaybackViewModel

    public init(viewModel: AudioPlaybackViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 12) {
            PlaybackWaveformView(
                audioSamples: viewModel.waveformSamples,
                currentProgress: viewModel.progress
            )
            .frame(height: 60)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let width = value.startLocation.x + value.translation.width
                        let progress = width / 300
                        viewModel.seek(toProgress: progress)
                    }
            )

            HStack {
                Text(formatTime(viewModel.currentTime))
                    .font(.caption.monospacedDigit())
                Spacer()
                Text(formatTime(viewModel.duration))
                    .font(.caption.monospacedDigit())
            }
            .foregroundColor(.secondary)

            HStack(spacing: 32) {
                Button {
                    viewModel.skip(seconds: -15)
                } label: {
                    Image(systemName: "gobackward.15")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.currentTime <= 0)

                Button {
                    viewModel.togglePlayback()
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.skip(seconds: 15)
                } label: {
                    Image(systemName: "goforward.15")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.currentTime >= viewModel.duration)
            }
        }
        .padding()
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
