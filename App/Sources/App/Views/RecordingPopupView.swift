import SwiftUI

public struct RecordingPopupView: View {
    @ObservedObject var viewModel: RecordingViewModel
    @StateObject private var settings = AppSettings.shared

    public init(viewModel: RecordingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Content area - switches between waveform and loading indicator
            Group {
                if viewModel.state.isProcessing {
                    // Transcribing state - show loading indicator
                    TranscribingView()
                } else {
                    // Recording state - show waveform
                    WaveformView(level: viewModel.audioLevel, barCount: 40)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom toolbar
            HStack {
                // Left side - Model selector
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.dashed")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text(settings.selectedModel.displayName)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                }

                Spacer()

                // Right side - Action buttons (only show during recording)
                if !viewModel.state.isProcessing {
                    HStack(spacing: 16) {
                        // Stop button
                        Button {
                            Task {
                                await viewModel.stopRecording()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text("Stop")
                                    .font(.system(size: 13))
                                KeyboardShortcutBadge(keys: ["⌃", "Space"])
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.primary)

                        // Cancel button
                        Button {
                            Task {
                                await viewModel.cancelRecording()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text("Cancel")
                                    .font(.system(size: 13))
                                KeyboardShortcutBadge(keys: ["esc"])
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.primary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        }
        .frame(width: 420, height: 140)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// Transcribing loading indicator
struct TranscribingView: View {
    var body: some View {
        HStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.0)
                .progressViewStyle(CircularProgressViewStyle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Transcribing...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)

                Text("Converting speech to text")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// Keyboard shortcut badge component
struct KeyboardShortcutBadge: View {
    let keys: [String]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(keys, id: \.self) { key in
                Text(key)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(nsColor: .controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
}

#Preview {
    RecordingPopupView(viewModel: RecordingViewModel())
        .frame(width: 450, height: 180)
}
