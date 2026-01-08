import Foundation

public struct WhisperModel: Identifiable, Equatable, Hashable {
    public let id: String
    public let name: String
    public let displayName: String
    public let sizeMB: Int
    public var isDownloaded: Bool

    public init(name: String, displayName: String, sizeMB: Int, isDownloaded: Bool = false) {
        self.id = name
        self.name = name
        self.displayName = displayName
        self.sizeMB = sizeMB
        self.isDownloaded = isDownloaded
    }

    public var sizeDescription: String {
        if sizeMB >= 1000 {
            return String(format: "%.1f GB", Double(sizeMB) / 1000.0)
        }
        return "\(sizeMB) MB"
    }

    /// Threshold in MB above which downloads require user confirmation
    public static let downloadConfirmationThresholdMB: Int = 100

    /// Whether this model requires user confirmation before downloading
    public var requiresDownloadConfirmation: Bool {
        sizeMB > Self.downloadConfirmationThresholdMB
    }

    /// Find a model by its name
    public static func model(named name: String) -> WhisperModel? {
        availableModels.first { $0.name == name }
    }

    nonisolated(unsafe) public static let availableModels: [WhisperModel] = [
        WhisperModel(name: "openai_whisper-base", displayName: "Base", sizeMB: 74),
        WhisperModel(name: "openai_whisper-small", displayName: "Small", sizeMB: 244),
        WhisperModel(name: "openai_whisper-medium", displayName: "Medium", sizeMB: 769),
        WhisperModel(name: "openai_whisper-large-v3", displayName: "Large V3", sizeMB: 1550),
        WhisperModel(name: "distil-whisper_distil-large-v3", displayName: "Distil Large V3", sizeMB: 756),
    ]

    nonisolated(unsafe) public static let defaultModel = availableModels.first!
}
