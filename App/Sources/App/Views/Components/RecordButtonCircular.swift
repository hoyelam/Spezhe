import SwiftUI

public struct RecordButtonCircular: View {
    @EnvironmentObject private var viewModel: RecordingViewModel

    public var body: some View {
        Button(action: {
            Task {
                await viewModel.toggleRecording()
            }
        }) {
            ZStack {
                Circle()
                    .fill(viewModel.state.isRecording ? Color.accentColor.opacity(0.2) : Color.clear)
                    .frame(width: 60, height: 60)

                Circle()
                    .stroke(Color.accentColor, lineWidth: 3)
                    .frame(width: 50, height: 50)

                if viewModel.state.isRecording {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.accentColor)
                        .frame(width: 20, height: 20)
                } else {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 36, height: 36)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(viewModel.state.isProcessing)
        .opacity(viewModel.state.isProcessing ? 0.5 : 1)
        .help(viewModel.state.isRecording ? "Stop Recording" : "Start Recording")
    }
}
