import Foundation
import Combine

@MainActor
public class RecordingViewModel: ObservableObject {
    @Published public var state: RecordingState = .idle
    @Published public var audioLevel: Float = 0
    @Published public var lastTranscription: String?
    @Published public var isPopupVisible = false
    @Published public var newRecordingID: Int64?

    // Download confirmation properties
    @Published public var pendingDownloadModel: WhisperModel?
    @Published public var showDownloadConfirmation = false

    public var onShowPopup: ((Bool) -> Void)?

    private let audioService = AudioRecordingService()
    private let transcriptionService = TranscriptionService()
    private let summarizationService = SummarizationService.shared
    private let clipboardService = ClipboardService.shared
    private let settings = AppSettings.shared

    private var cancellables = Set<AnyCancellable>()
    private var modelLoadTask: Task<Void, Never>?

    public init() {
        logDebug("RecordingViewModel initialized", category: .app)
        setupBindings()
        loadModelIfNeeded()
    }

    private func setupBindings() {
        audioService.$audioLevel
            .receive(on: DispatchQueue.main)
            .assign(to: &$audioLevel)
    }

    private func loadModelIfNeeded() {
        let modelName = settings.selectedModelName
        logInfo("Pre-loading model: \(modelName)", category: .app)

        modelLoadTask = Task {
            // Check if model is already downloaded
            await ModelManagerService.shared.refreshDownloadedModels()
            let isDownloaded = ModelManagerService.shared.isModelDownloaded(modelName)

            if isDownloaded {
                // Model is downloaded, load it directly
                do {
                    try await transcriptionService.loadModel(named: modelName)
                    logInfo("Model pre-loaded successfully", category: .app)
                } catch {
                    logError("Failed to pre-load model: \(error.localizedDescription)", category: .app)
                }
            } else {
                // Model not downloaded - check if it requires confirmation
                guard let model = WhisperModel.model(named: modelName) else {
                    logError("Unknown model: \(modelName)", category: .app)
                    return
                }

                if model.requiresDownloadConfirmation {
                    // Large model - require user confirmation
                    logInfo("Model \(modelName) requires download confirmation (\(model.sizeDescription))", category: .app)
                    pendingDownloadModel = model
                    showDownloadConfirmation = true
                } else {
                    // Small model (e.g., Base) - download silently
                    logInfo("Downloading small model \(modelName) (\(model.sizeDescription))", category: .app)
                    do {
                        try await ModelManagerService.shared.downloadModel(model)
                        try await transcriptionService.loadModel(named: modelName)
                        logInfo("Model downloaded and pre-loaded successfully", category: .app)
                    } catch {
                        logError("Failed to download/load model: \(error.localizedDescription)", category: .app)
                    }
                }
            }
        }
    }

    public func toggleRecording() async {
        logDebug("toggleRecording() called, current state: \(state)", category: .app)

        switch state {
        case .idle, .completed, .error:
            await startRecording()
        case .recording:
            await stopRecording()
        case .loadingModel, .processing:
            logWarning("toggleRecording() ignored - currently processing", category: .app)
            break
        }
    }

    private func startRecording() async {
        logInfo("Starting recording flow...", category: .app)

        do {
            if !transcriptionService.isModelLoaded {
                logInfo("Model not loaded, loading now...", category: .app)
                state = .loadingModel
                showPopup(true)

                let modelName = settings.selectedModelName
                let isDownloaded = ModelManagerService.shared.isModelDownloaded(modelName)

                if isDownloaded {
                    // Model is downloaded, load it
                    try await transcriptionService.loadModel(named: modelName)
                } else {
                    // Model not downloaded - check if it requires confirmation
                    guard let model = WhisperModel.model(named: modelName) else {
                        throw RecordingError.unknownModel(modelName)
                    }

                    if model.requiresDownloadConfirmation {
                        // Large model needs confirmation - fallback to Base
                        logInfo("Model \(modelName) not downloaded and requires confirmation, falling back to Base", category: .app)
                        let baseModel = WhisperModel.defaultModel

                        // Check if Base is downloaded
                        if ModelManagerService.shared.isModelDownloaded(baseModel.name) {
                            settings.selectedModelName = baseModel.name
                            try await transcriptionService.loadModel(named: baseModel.name)
                        } else {
                            // Download Base silently (it's small)
                            logInfo("Downloading Base model for fallback", category: .app)
                            try await ModelManagerService.shared.downloadModel(baseModel)
                            settings.selectedModelName = baseModel.name
                            try await transcriptionService.loadModel(named: baseModel.name)
                        }
                    } else {
                        // Small model - download silently
                        logInfo("Downloading small model \(modelName)", category: .app)
                        try await ModelManagerService.shared.downloadModel(model)
                        try await transcriptionService.loadModel(named: modelName)
                    }
                }
            }

            state = .recording
            showPopup(true)
            logDebug("State set to .recording, popup shown", category: .app)

            try await audioService.startRecording()
            logInfo("Recording started", category: .app)
        } catch {
            logError("Failed to start recording: \(error.localizedDescription)", category: .app)
            state = .error(error.localizedDescription)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.state = .idle
                self?.showPopup(false)
            }
        }
    }

    public func stopRecording() async {
        logInfo("Stopping recording flow...", category: .app)

        do {
            logDebug("Stopping audio service...", category: .app)
            let audioResult = try await audioService.stopRecording()
            logInfo("Audio captured: \(audioResult.samples.count) samples, duration: \(audioResult.duration)s", category: .app)

            state = .processing
            logDebug("State set to .processing", category: .app)

            logDebug("Starting transcription...", category: .app)
            let transcriptionResult = try await transcriptionService.transcribe(audioArray: audioResult.samples)
            logInfo("Transcription successful: '\(transcriptionResult.text)'", category: .app)

            // Generate AI summaries (one-liner + summary)
            let (oneLiner, summary) = await summarizationService.generateSummaries(from: transcriptionResult.text)
            if let ol = oneLiner {
                logInfo("AI one-liner generated: '\(ol)'", category: .app)
            }
            if let s = summary {
                logInfo("AI summary generated: '\(s)'", category: .app)
            }

            // Save audio file
            let (audioFileName, fileSize) = try AudioFileManager.shared.saveAudio(
                audioResult.samples,
                sampleRate: audioResult.sampleRate
            )
            logInfo("Audio saved: \(audioFileName), size: \(fileSize) bytes", category: .app)

            // Create and save recording to database
            var recording = Recording(
                title: "",
                transcriptionText: transcriptionResult.text,
                oneLiner: oneLiner,
                summary: summary,
                audioFileName: audioFileName,
                createdAt: Date(),
                duration: audioResult.duration,
                detectedLanguage: transcriptionResult.detectedLanguage,
                wordCount: transcriptionResult.text.split(separator: " ").count,
                modelUsed: settings.selectedModelName,
                fileSize: fileSize
            )
            recording.generateDefaultTitle()

            try RecordingRepository.shared.insert(&recording)
            logInfo("Recording saved to database with ID: \(recording.id ?? -1)", category: .app)

            // Notify UI of new recording
            newRecordingID = recording.id

            lastTranscription = transcriptionResult.text
            state = .completed(transcriptionResult.text)
            logDebug("State set to .completed", category: .app)

            if settings.autoPasteEnabled {
                logDebug("Auto-paste enabled, preparing to paste...", category: .app)
                showPopup(false)

                try await Task.sleep(nanoseconds: 100_000_000)

                logDebug("Attempting to copy and paste...", category: .clipboard)
                let success = clipboardService.copyAndPaste(transcriptionResult.text)
                if success {
                    logInfo("Text pasted successfully", category: .clipboard)
                } else {
                    logWarning("Paste failed (accessibility?), text copied to clipboard only", category: .clipboard)
                    clipboardService.copyToClipboard(transcriptionResult.text)
                }
            } else {
                logDebug("Auto-paste disabled, text available in popup", category: .app)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                if case .completed = self?.state {
                    logDebug("Auto-hiding popup after completion", category: .app)
                    self?.state = .idle
                    self?.showPopup(false)
                }
            }
        } catch {
            logError("Recording flow failed: \(error.localizedDescription)", category: .app)
            state = .error(error.localizedDescription)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.state = .idle
                self?.showPopup(false)
            }
        }
    }

    public func cancelRecording() async {
        logInfo("Cancelling recording...", category: .app)
        _ = try? await audioService.stopRecording()
        state = .idle
        showPopup(false)
        logDebug("Recording cancelled", category: .app)
    }

    private func showPopup(_ show: Bool) {
        logDebug("showPopup(\(show))", category: .ui)
        isPopupVisible = show
        onShowPopup?(show)
    }

    public func reloadModel() async {
        await reloadModelIfNeeded(settings.selectedModelName)
    }

    public func reloadModelIfNeeded(_ modelName: String) async {
        // Skip if already loading a model
        guard modelLoadTask == nil || modelLoadTask?.isCancelled == true else {
            logDebug("Model load already in progress, skipping reload", category: .app)
            return
        }

        // Skip if the requested model is already loaded
        if transcriptionService.isModelLoaded && transcriptionService.loadedModelName == modelName {
            logDebug("Model '\(modelName)' already loaded, skipping reload", category: .app)
            return
        }

        logInfo("Reloading model: \(modelName)", category: .app)
        transcriptionService.unloadModel()
        do {
            try await transcriptionService.loadModel(named: modelName)
            logInfo("Model reloaded successfully", category: .app)
        } catch {
            logError("Failed to reload model: \(error.localizedDescription)", category: .app)
        }
    }

    // MARK: - Download Confirmation Handlers

    /// User confirmed download of a large model
    public func confirmDownload() async {
        guard let model = pendingDownloadModel else {
            logWarning("confirmDownload called but no pending model", category: .app)
            return
        }

        logInfo("User confirmed download of \(model.name)", category: .app)
        showDownloadConfirmation = false

        do {
            try await ModelManagerService.shared.downloadModel(model)
            try await transcriptionService.loadModel(named: model.name)
            logInfo("Model \(model.name) downloaded and loaded successfully", category: .app)
        } catch {
            logError("Failed to download/load model: \(error.localizedDescription)", category: .app)
            state = .error("Failed to download model: \(error.localizedDescription)")
        }

        pendingDownloadModel = nil
    }

    /// User declined download - fallback to Base model
    public func declineDownload() {
        guard let model = pendingDownloadModel else {
            logWarning("declineDownload called but no pending model", category: .app)
            return
        }

        logInfo("User declined download of \(model.name), falling back to Base", category: .app)
        showDownloadConfirmation = false
        pendingDownloadModel = nil

        // Update settings to use Base model
        settings.selectedModelName = WhisperModel.defaultModel.name

        // Trigger load of Base model
        loadModelIfNeeded()
    }
}

// MARK: - Recording Errors

public enum RecordingError: LocalizedError {
    case unknownModel(String)

    public var errorDescription: String? {
        switch self {
        case .unknownModel(let name):
            return "Unknown model: \(name)"
        }
    }
}
