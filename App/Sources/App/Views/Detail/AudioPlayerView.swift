import SwiftUI

public struct AudioPlayerView: View {
    @ObservedObject var viewModel: AudioPlaybackViewModel
    private let isEnabled: Bool

    public init(viewModel: AudioPlaybackViewModel, isEnabled: Bool = true) {
        self.viewModel = viewModel
        self.isEnabled = isEnabled
    }

    public var body: some View {
        VStack(spacing: 12) {
            GeometryReader { geometry in
                PlaybackWaveformView(
                    audioSamples: viewModel.waveformSamples,
                    currentProgress: viewModel.progress
                )
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let width = max(1, geometry.size.width)
                            let clampedX = min(max(0, value.location.x), width)
                            let progress = clampedX / width
                            viewModel.seek(toProgress: progress)
                        }
                )
            }
            .frame(height: 60)

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
                .foregroundColor(.accentColor)
                .disabled(viewModel.currentTime <= 0)

                Button {
                    viewModel.togglePlayback()
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 44))
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)

                Button {
                    viewModel.skip(seconds: 15)
                } label: {
                    Image(systemName: "goforward.15")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)
                .disabled(viewModel.currentTime >= viewModel.duration)
            }
        }
        .padding()
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
