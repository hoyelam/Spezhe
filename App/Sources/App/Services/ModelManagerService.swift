import Foundation
import WhisperKit

@MainActor
public class ModelManagerService: ObservableObject {
    public static let shared = ModelManagerService()

    @Published public var downloadProgress: [String: ModelDownloadProgress] = [:]
    @Published public var downloadedModels: Set<String> = []

    private init() {
        logDebug("ModelManagerService initialized", category: .model)
        Task {
            await refreshDownloadedModels()
        }
    }

    public func refreshDownloadedModels() async {
        logDebug("Refreshing list of downloaded models...", category: .model)
        let localModels = localDownloadedModelNames()
        downloadedModels = localModels
        logInfo("Found \(downloadedModels.count) downloaded models: \(downloadedModels.sorted())", category: .model)
    }

    public func isModelDownloaded(_ modelName: String) -> Bool {
        let downloaded = downloadedModels.contains(modelName)
        logDebug("isModelDownloaded('\(modelName)') = \(downloaded)", category: .model)
        return downloaded
    }

    public func downloadModel(_ model: WhisperModel) async throws {
        if downloadProgress[model.name] != nil {
            logWarning("Download already in progress for \(model.name)", category: .model)
            return
        }

        if downloadedModels.contains(model.name) {
            logInfo("Model \(model.name) already downloaded, skipping", category: .model)
            return
        }

        logInfo("Downloading model: \(model.name) (\(model.sizeDescription))", category: .model)
        let totalBytes = ModelManagerService.estimatedTotalBytes(for: model)
        downloadProgress[model.name] = ModelDownloadProgress(fractionCompleted: 0, totalBytes: totalBytes)

        let startTime = Date()
        AnalyticsService.shared.track(.modelDownloadStarted, properties: [
            "model_name": model.name,
            "size_description": model.sizeDescription
        ])

        do {
            logDebug("Downloading model via WhisperKit...", category: .model)
            _ = try await WhisperKit.download(variant: model.name, progressCallback: { progress in
                let fraction = progress.fractionCompleted
                let update = ModelDownloadProgress(fractionCompleted: fraction, totalBytes: totalBytes)
                Task { @MainActor [weak self] in
                    guard let self, self.downloadProgress[model.name] != nil else { return }
                    self.downloadProgress[model.name] = update
                }
            })

            let downloadTime = Date().timeIntervalSince(startTime)
            downloadProgress.removeValue(forKey: model.name)
            downloadedModels.insert(model.name)
            logInfo("Model '\(model.name)' downloaded successfully in \(String(format: "%.2f", downloadTime)) seconds", category: .model)
            AnalyticsService.shared.track(.modelDownloadCompleted, properties: [
                "model_name": model.name,
                "size_description": model.sizeDescription,
                "download_duration_sec": downloadTime
            ])
        } catch {
            downloadProgress.removeValue(forKey: model.name)
            logError("Failed to download model '\(model.name)': \(error.localizedDescription)", category: .model)
            let nsError = error as NSError
            AnalyticsService.shared.track(.modelDownloadFailed, properties: [
                "model_name": model.name,
                "size_description": model.sizeDescription,
                "error_domain": nsError.domain,
                "error_code": nsError.code
            ])
            throw ModelManagerError.downloadFailed(error.localizedDescription)
        }
    }

    public func deleteModel(_ model: WhisperModel) throws {
        if model.isDefault {
            logWarning("Attempted to delete default model \(model.name)", category: .model)
            throw ModelManagerError.deleteNotAllowed
        }

        logInfo("Deleting model: \(model.name)", category: .model)

        let fileManager = FileManager.default
        guard let modelsPath = modelsDirectoryURL() else {
            logError("Could not find Documents directory", category: .model)
            throw ModelManagerError.directoryNotFound
        }

        let matchingFolders = localModelFolders(in: modelsPath)
            .filter { matchesDownloadedFolder($0, model: model) }
            .map { modelsPath.appendingPathComponent($0) }

        if matchingFolders.isEmpty {
            logWarning("No model folders found for \(model.name)", category: .model)
            return
        }

        for folder in matchingFolders {
            logDebug("Removing model folder: \(folder.path)", category: .model)
            try fileManager.removeItem(at: folder)
        }

        downloadedModels.remove(model.name)
        logInfo("Model '\(model.name)' deleted successfully", category: .model)
    }

    public func getModelsDirectorySize() -> Int64 {
        let fileManager = FileManager.default
        guard let modelsPath = modelsDirectoryURL(), fileManager.fileExists(atPath: modelsPath.path) else {
            return 0
        }

        let size = directorySize(at: modelsPath)
        logDebug("Models directory size: \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))", category: .model)
        return size
    }

    private func directorySize(at url: URL) -> Int64 {
        let fileManager = FileManager.default
        var size: Int64 = 0

        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [], errorHandler: nil) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                size += Int64(fileSize)
            }
        }

        return size
    }

    private func localDownloadedModelNames() -> Set<String> {
        guard let modelsPath = modelsDirectoryURL() else {
            return []
        }

        let folders = localModelFolders(in: modelsPath)
        let downloaded = WhisperModel.availableModels.filter { model in
            folders.contains { matchesDownloadedFolder($0, model: model) }
        }
        return Set(downloaded.map { $0.name })
    }

    private func localModelFolders(in modelsPath: URL) -> [String] {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: modelsPath.path) else {
            return []
        }

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: modelsPath,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            return contents.compactMap { url in
                let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                return isDirectory ? url.lastPathComponent : nil
            }
        } catch {
            logError("Failed to list models directory: \(error.localizedDescription)", category: .model)
            return []
        }
    }

    private func matchesDownloadedFolder(_ folderName: String, model: WhisperModel) -> Bool {
        if folderName == model.name {
            return true
        }
        if folderName.hasPrefix(model.name + "_") || folderName.hasPrefix(model.name + "-") {
            return true
        }
        return false
    }

    private func modelsDirectoryURL() -> URL? {
        guard let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        return documentsDir
            .appendingPathComponent("huggingface")
            .appendingPathComponent("models")
            .appendingPathComponent("argmaxinc")
            .appendingPathComponent("whisperkit-coreml")
    }

    private static func estimatedTotalBytes(for model: WhisperModel) -> Int64 {
        Int64(model.sizeMB) * 1_000_000
    }
}

public struct ModelDownloadProgress: Equatable {
    public let fractionCompleted: Double
    public let completedBytes: Int64
    public let totalBytes: Int64

    public init(fractionCompleted: Double, totalBytes: Int64) {
        let clamped = max(0, min(1, fractionCompleted))
        let clampedTotal = max(0, totalBytes)
        self.fractionCompleted = clamped
        self.totalBytes = clampedTotal
        self.completedBytes = Int64(Double(clampedTotal) * clamped)
    }

    public var remainingBytes: Int64 {
        max(0, totalBytes - completedBytes)
    }
}

public enum ModelManagerError: LocalizedError {
    case downloadFailed(String)
    case directoryNotFound
    case deleteFailed(String)
    case deleteNotAllowed

    public var errorDescription: String? {
        switch self {
        case .downloadFailed(let reason):
            return "Download failed: \(reason)"
        case .directoryNotFound:
            return "Models directory not found"
        case .deleteFailed(let reason):
            return "Delete failed: \(reason)"
        case .deleteNotAllowed:
            return "The Base model cannot be deleted"
        }
    }
}
