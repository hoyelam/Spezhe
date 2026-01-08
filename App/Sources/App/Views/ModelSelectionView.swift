import SwiftUI

public struct ModelSelectionView: View {
    @ObservedObject var viewModel: ModelDownloadViewModel
    @Binding var selectedModelName: String

    public init(viewModel: ModelDownloadViewModel, selectedModelName: Binding<String>) {
        self.viewModel = viewModel
        self._selectedModelName = selectedModelName
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Whisper Models")
                .font(.headline)

            Text("Storage used: \(viewModel.totalStorageUsed)")
                .font(.caption)
                .foregroundColor(.secondary)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            List(viewModel.models) { model in
                ModelRowView(
                    model: model,
                    isSelected: model.name == selectedModelName,
                    downloadProgress: viewModel.downloadProgress[model.name],
                    onSelect: {
                        if model.isDownloaded {
                            selectedModelName = model.name
                        }
                    },
                    onDownload: {
                        viewModel.downloadModel(model)
                    },
                    onDelete: {
                        viewModel.deleteModel(model)
                    }
                )
            }
            .listStyle(.inset)
        }
        .padding()
    }
}

struct ModelRowView: View {
    let model: WhisperModel
    let isSelected: Bool
    let downloadProgress: Double?
    let onSelect: () -> Void
    let onDownload: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(model.displayName)
                        .font(.body)
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                            .font(.caption)
                    }
                }
                Text(model.sizeDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let progress = downloadProgress, progress < 1.0 {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .frame(width: 60)
            } else if model.isDownloaded {
                HStack(spacing: 8) {
                    if !isSelected {
                        Button("Select") {
                            onSelect()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.red)
                }
            } else {
                Button("Download") {
                    onDownload()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
        .background {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    if model.isDownloaded {
                        onSelect()
                    }
                }
        }
    }
}

#Preview {
    ModelSelectionView(
        viewModel: ModelDownloadViewModel(),
        selectedModelName: .constant("openai_whisper-base")
    )
    .frame(width: 400, height: 400)
}
