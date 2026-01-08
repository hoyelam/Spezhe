import Foundation
import WhisperKit

@MainActor
public class ModelManagerService: ObservableObject {
    public static let shared = ModelManagerService()

    @Published public var downloadProgress: [String: Double] = [:]
    @Published public var downloadedModels: Set<String> = []

    private init() {
        logDebug("ModelManagerService initialized", category: .model)
        Task {
            await refreshDownloadedModels()
        }
    }

    public func refreshDownloadedModels() async {
        logDebug("Refreshing list of downloaded models...", category: .model)
        let localModels = (try? await WhisperKit.fetchAvailableModels()) ?? []
        downloadedModels = Set(localModels)
        logInfo("Found \(downloadedModels.count) downloaded models: \(downloadedModels.sorted())", category: .model)
    }

    public func isModelDownloaded(_ modelName: String) -> Bool {
        let downloaded = downloadedModels.contains(modelName)
        logDebug("isModelDownloaded('\(modelName)') = \(downloaded)", category: .model)
        return downloaded
    }

    public func downloadModel(_ model: WhisperModel) async throws {
        logInfo("Downloading model: \(model.name) (\(model.sizeDescription))", category: .model)
        downloadProgress[model.name] = 0

        let startTime = Date()

        do {
            logDebug("Creating WhisperKitConfig for download...", category: .model)
            let config = WhisperKitConfig(model: model.name)

            logDebug("Initializing WhisperKit to trigger download...", category: .model)
            _ = try await WhisperKit(config)

            let downloadTime = Date().timeIntervalSince(startTime)
            downloadProgress[model.name] = 1.0
            downloadedModels.insert(model.name)
            logInfo("Model '\(model.name)' downloaded successfully in \(String(format: "%.2f", downloadTime)) seconds", category: .model)
        } catch {
            downloadProgress.removeValue(forKey: model.name)
            logError("Failed to download model '\(model.name)': \(error.localizedDescription)", category: .model)
            throw ModelManagerError.downloadFailed(error.localizedDescription)
        }
    }

    public func deleteModel(_ model: WhisperModel) throws {
        logInfo("Deleting model: \(model.name)", category: .model)

        let fileManager = FileManager.default
        guard let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            logError("Could not find Documents directory", category: .model)
            throw ModelManagerError.directoryNotFound
        }

        let modelPath = documentsDir
            .appendingPathComponent("huggingface")
            .appendingPathComponent("models")
            .appendingPathComponent("argmaxinc")
            .appendingPathComponent("whisperkit-coreml")
            .appendingPathComponent(model.name)

        logDebug("Model path: \(modelPath.path)", category: .model)

        if fileManager.fileExists(atPath: modelPath.path) {
            try fileManager.removeItem(at: modelPath)
            downloadedModels.remove(model.name)
            logInfo("Model '\(model.name)' deleted successfully", category: .model)
        } else {
            logWarning("Model path does not exist: \(modelPath.path)", category: .model)
        }
    }

    public func getModelsDirectorySize() -> Int64 {
        let fileManager = FileManager.default
        guard let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return 0
        }

        let modelsPath = documentsDir
            .appendingPathComponent("huggingface")
            .appendingPathComponent("models")
            .appendingPathComponent("argmaxinc")
            .appendingPathComponent("whisperkit-coreml")

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
}

public enum ModelManagerError: LocalizedError {
    case downloadFailed(String)
    case directoryNotFound
    case deleteFailed(String)

    public var errorDescription: String? {
        switch self {
        case .downloadFailed(let reason):
            return "Download failed: \(reason)"
        case .directoryNotFound:
            return "Models directory not found"
        case .deleteFailed(let reason):
            return "Delete failed: \(reason)"
        }
    }
}
