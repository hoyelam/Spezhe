import Foundation
import Combine

@MainActor
public class ModelDownloadViewModel: ObservableObject {
    @Published public var models: [WhisperModel] = WhisperModel.availableModels
    @Published public var downloadProgress: [String: ModelDownloadProgress] = [:]
    @Published public var errorMessage: String?
    @Published public var isDownloading = false

    private let modelManager = ModelManagerService.shared
    private var cancellables = Set<AnyCancellable>()

    public init() {
        setupBindings()
        refreshModels()
    }

    private func setupBindings() {
        modelManager.$downloadedModels
            .receive(on: DispatchQueue.main)
            .sink { [weak self] downloadedModels in
                self?.updateModelsDownloadStatus(downloadedModels)
            }
            .store(in: &cancellables)

        modelManager.$downloadProgress
            .receive(on: DispatchQueue.main)
            .assign(to: &$downloadProgress)
    }

    private func updateModelsDownloadStatus(_ downloadedModels: Set<String>) {
        models = WhisperModel.availableModels.map { model in
            var updatedModel = model
            updatedModel.isDownloaded = downloadedModels.contains(model.name)
            return updatedModel
        }
    }

    public func refreshModels() {
        Task {
            await modelManager.refreshDownloadedModels()
        }
    }

    public func downloadModel(_ model: WhisperModel) {
        guard !isDownloading else { return }

        isDownloading = true
        errorMessage = nil

        Task {
            do {
                try await modelManager.downloadModel(model)
            } catch {
                errorMessage = error.localizedDescription
            }
            isDownloading = false
        }
    }

    public func deleteModel(_ model: WhisperModel) {
        do {
            try modelManager.deleteModel(model)
            refreshModels()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public var totalStorageUsed: String {
        let bytes = modelManager.getModelsDirectorySize()
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
