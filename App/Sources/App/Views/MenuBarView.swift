import SwiftUI

public struct MenuBarView: View {
    @ObservedObject var viewModel: RecordingViewModel
    @StateObject private var settingsViewModel = SettingsViewModel()

    public init(viewModel: RecordingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(viewModel.state.statusText)
                    .font(.headline)
                Spacer()
            }

            if let lastText = viewModel.lastTranscription {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last transcription:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(lastText)
                        .font(.caption)
                        .lineLimit(3)
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 4)
            }

            Divider()

            Text("Shortcut: ⌘⌃1")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Text("Model:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(AppSettings.shared.selectedModel.displayName)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .frame(width: 260)
    }

    private var statusColor: Color {
        switch viewModel.state {
        case .idle:
            return .gray
        case .recording:
            return .red
        case .processing:
            return .orange
        case .completed:
            return .green
        case .error:
            return .red
        }
    }
}

#Preview {
    MenuBarView(viewModel: RecordingViewModel())
}
