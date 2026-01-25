import SwiftUI
import Foundation

public struct ModelSelectionView: View {
    @ObservedObject var viewModel: ModelDownloadViewModel
    @Binding var selectedModelName: String

    public init(viewModel: ModelDownloadViewModel, selectedModelName: Binding<String>) {
        self.viewModel = viewModel
        self._selectedModelName = selectedModelName
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.Models.title)
                .font(.headline)

            Text(L10n.Models.storageUsed(viewModel.totalStorageUsed))
                .font(.caption)
                .foregroundColor(.secondary)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            List(viewModel.models) { model in
                let isDownloadingModel = viewModel.downloadProgress[model.name] != nil
                ModelRowView(
                    model: model,
                    isSelected: model.name == selectedModelName,
                    downloadProgress: viewModel.downloadProgress[model.name],
                    isDownloadDisabled: viewModel.isDownloading && !isDownloadingModel,
                    onSelect: {
                        if model.isDownloaded || model.isDefault {
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
    let downloadProgress: ModelDownloadProgress?
    let isDownloadDisabled: Bool
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
                if let progress = downloadProgress, progress.fractionCompleted < 1.0 {
                    Text(downloadStatusText(for: progress))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else if isDownloadDisabled && !model.isDownloaded {
                    Text(L10n.Models.anotherModelDownloading)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let progress = downloadProgress, progress.fractionCompleted < 1.0 {
                ProgressView(value: progress.fractionCompleted)
                    .progressViewStyle(.linear)
                    .frame(width: 60)
            } else if model.isDownloaded {
                HStack(spacing: 8) {
                    if !isSelected {
                        Button(L10n.Common.select) {
                            onSelect()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    if !model.isDefault {
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
                }
            } else {
                if model.isDefault && !isSelected {
                    Button("Select") {
                        onSelect()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                } else {
                    Button(L10n.Common.download) {
                        onDownload()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(isDownloadDisabled)
                }
            }
        }
        .padding(.vertical, 4)
        .background {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    if model.isDownloaded || model.isDefault {
                        onSelect()
                    }
                }
        }
    }

    private func downloadStatusText(for progress: ModelDownloadProgress) -> String {
        let completed = ByteCountFormatter.string(fromByteCount: progress.completedBytes, countStyle: .file)
        let total = ByteCountFormatter.string(fromByteCount: progress.totalBytes, countStyle: .file)
        return L10n.Models.downloadingProgress(completed, total)
    }
}

#Preview {
    ModelSelectionView(
        viewModel: ModelDownloadViewModel(),
        selectedModelName: .constant("openai_whisper-base")
    )
    .frame(width: 400, height: 400)
}
