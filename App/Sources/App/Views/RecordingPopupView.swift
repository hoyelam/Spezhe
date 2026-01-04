import SwiftUI

public struct RecordingPopupView: View {
    @ObservedObject var viewModel: RecordingViewModel

    public init(viewModel: RecordingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 16) {
            WaveformView(level: viewModel.audioLevel)
                .frame(height: 40)

            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)

            if viewModel.state.isRecording {
                Button("Cancel") {
                    Task {
                        await viewModel.cancelRecording()
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
                .font(.caption)
            }

            if case .completed(let text) = viewModel.state {
                Text(text)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(width: 220, height: 130)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var statusText: String {
        switch viewModel.state {
        case .idle:
            return "Press ⌘⌃1 to start"
        case .recording:
            return "Recording... Press ⌘⌃1 to stop"
        case .processing:
            return "Transcribing..."
        case .completed:
            return "Done!"
        case .error(let message):
            return message
        }
    }
}

#Preview {
    RecordingPopupView(viewModel: RecordingViewModel())
        .frame(width: 300, height: 200)
}
