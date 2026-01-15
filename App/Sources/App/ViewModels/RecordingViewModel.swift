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
    private let soundFeedbackService = SoundFeedbackService.shared
    private let settings = AppSettings.shared
    private let analytics = AnalyticsService.shared

    private var cancellables = Set<AnyCancellable>()
    private var modelLoadTask: Task<Void, Error>?
    private var modelLoadTargetName: String?

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
        startModelLoadIfNeeded()
    }

    private func startModelLoadIfNeeded() {
        let activeProfile = settings.activeProfile
        let modelName = settings.resolvedModelName(for: activeProfile)
        Task { [weak self] in
            guard let self else { return }
            do {
                try await ensureModelLoaded(
                    named: modelName,
                    allowFallbackIfNeedsConfirmation: false,
                    bypassDownloadConfirmation: false,
                    context: "pre-load"
                )
                if transcriptionService.isModelLoaded && transcriptionService.loadedModelName == modelName {
                    logInfo("Model pre-loaded successfully", category: .app)
                }
            } catch {
                logError("Failed to pre-load model: \(error.localizedDescription)", category: .app)
            }
        }
    }

    private func ensureModelLoaded(
        named modelName: String,
        allowFallbackIfNeedsConfirmation: Bool,
        bypassDownloadConfirmation: Bool,
        context: String
    ) async throws {
        if transcriptionService.isModelLoaded && transcriptionService.loadedModelName == modelName {
            return
        }

        if let existingTask = modelLoadTask, modelLoadTargetName == modelName {
            logDebug("Model \(modelName) already loading (\(context)), awaiting", category: .app)
            try await existingTask.value
            return
        }

        if let existingTask = modelLoadTask {
            logInfo("Cancelling model load for \(modelLoadTargetName ?? "unknown") in favor of \(modelName)", category: .app)
            existingTask.cancel()
        }

        modelLoadTargetName = modelName
        logInfo("Loading model (\(context)): \(modelName)", category: .app)
        modelLoadTask = Task { [weak self] in
            guard let self else { return }
            defer {
                if self.modelLoadTargetName == modelName {
                    self.modelLoadTask = nil
                    self.modelLoadTargetName = nil
                }
            }
            try await self.loadSelectedModel(
                named: modelName,
                allowFallbackIfNeedsConfirmation: allowFallbackIfNeedsConfirmation,
                bypassDownloadConfirmation: bypassDownloadConfirmation
            )
        }

        let loadTask = modelLoadTask
        try await loadTask?.value
    }

    private func loadSelectedModel(
        named modelName: String,
        allowFallbackIfNeedsConfirmation: Bool,
        bypassDownloadConfirmation: Bool
    ) async throws {
        if transcriptionService.isModelLoaded && transcriptionService.loadedModelName == modelName {
            return
        }

        await ModelManagerService.shared.refreshDownloadedModels()
        let isDownloaded = ModelManagerService.shared.isModelDownloaded(modelName)

        if isDownloaded {
            try await transcriptionService.loadModel(named: modelName)
            return
        }

        guard let model = WhisperModel.model(named: modelName) else {
            logError("Unknown model: \(modelName)", category: .app)
            throw RecordingError.unknownModel(modelName)
        }

        if model.requiresDownloadConfirmation && !bypassDownloadConfirmation {
            if allowFallbackIfNeedsConfirmation {
                logInfo("Model \(modelName) not downloaded and requires confirmation, falling back to Base", category: .app)
                let baseModel = WhisperModel.defaultModel

                if ModelManagerService.shared.isModelDownloaded(baseModel.name) {
                    settings.selectedModelName = baseModel.name
                    try await transcriptionService.loadModel(named: baseModel.name)
                } else {
                    logInfo("Downloading Base model for fallback", category: .app)
                    try await ModelManagerService.shared.downloadModel(baseModel)
                    settings.selectedModelName = baseModel.name
                    try await transcriptionService.loadModel(named: baseModel.name)
                }
            } else {
                logInfo("Model \(modelName) requires download confirmation (\(model.sizeDescription))", category: .app)
                pendingDownloadModel = model
                showDownloadConfirmation = true
            }
            return
        }

        logInfo("Downloading small model \(modelName) (\(model.sizeDescription))", category: .app)
        try await ModelManagerService.shared.downloadModel(model)
        try await transcriptionService.loadModel(named: modelName)
    }

    private func ensureModelReadyForTranscription(modelName: String) async throws {
        try await ensureModelLoaded(
            named: modelName,
            allowFallbackIfNeedsConfirmation: true,
            bypassDownloadConfirmation: false,
            context: "transcription"
        )
    }

    public func toggleRecording(source: RecordingTriggerSource = .unknown) async {
        logDebug("toggleRecording() called, current state: \(state)", category: .app)

        switch state {
        case .idle, .completed, .error:
            await startRecording(source: source)
        case .recording:
            await stopRecording(source: source)
        case .loadingModel, .processing:
            logWarning("toggleRecording() ignored - currently processing", category: .app)
            break
        }
    }

    private func startRecording(source: RecordingTriggerSource) async {
        logInfo("Starting recording flow...", category: .app)

        do {
            state = .recording
            showPopup(true)
            logDebug("State set to .recording, popup shown", category: .app)

            try await audioService.startRecording()
            soundFeedbackService.playRecordingStartSound()
            logInfo("Recording started", category: .app)
            let activeProfile = settings.activeProfile
            let modelName = settings.resolvedModelName(for: activeProfile)
            analytics.track(.recordingStarted, properties: analyticsContextProperties(source: source, profile: activeProfile, modelName: modelName))

            startModelLoadIfNeeded()
        } catch {
            logError("Failed to start recording: \(error.localizedDescription)", category: .app)
            state = .error(error.localizedDescription)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.state = .idle
                self?.showPopup(false)
            }
        }
    }

    public func stopRecording(source: RecordingTriggerSource = .unknown) async {
        logInfo("Stopping recording flow...", category: .app)
        soundFeedbackService.playRecordingStopSound()

        let activeProfile = settings.activeProfile
        let modelName = settings.resolvedModelName(for: activeProfile)
        let baseProperties = analyticsContextProperties(source: source, profile: activeProfile, modelName: modelName)
        var failureStage = "stop_recording"
        var audioDuration: Double?
        var samplesCount: Int?

        do {
            logDebug("Stopping audio service...", category: .app)
            let audioResult = try await audioService.stopRecording()
            logInfo("Audio captured: \(audioResult.samples.count) samples, duration: \(audioResult.duration)s", category: .app)

            audioDuration = audioResult.duration
            samplesCount = audioResult.samples.count
            var recordingStoppedProperties = baseProperties
            recordingStoppedProperties["duration_sec"] = audioResult.duration
            recordingStoppedProperties["samples_count"] = audioResult.samples.count
            analytics.track(.recordingStopped, properties: recordingStoppedProperties)

            if transcriptionService.isModelLoaded && transcriptionService.loadedModelName == modelName {
                state = .processing
                logDebug("State set to .processing", category: .app)
            } else {
                state = .loadingModel
                logDebug("State set to .loadingModel", category: .app)
            }

            failureStage = "model_load"
            try await ensureModelReadyForTranscription(modelName: modelName)
            let effectiveModelName = transcriptionService.loadedModelName ?? modelName
            state = .processing
            logDebug("State set to .processing", category: .app)

            // Get active profile settings
            let language = activeProfile?.language

            logDebug("Starting transcription...", category: .app)
            if let lang = language, lang != "auto" {
                logInfo("Using forced language from profile: \(lang)", category: .app)

                // Check if current model supports multilingual
                if let model = WhisperModel.model(named: effectiveModelName), !model.isMultilingual {
                    logWarning("Model '\(model.displayName)' is English-only. Language forcing to '\(lang)' may not work correctly.", category: .app)
                }
            }
            failureStage = "transcription"
            var transcriptionStartedProperties = baseProperties
            transcriptionStartedProperties["audio_duration_sec"] = audioResult.duration
            transcriptionStartedProperties["model_name"] = effectiveModelName
            analytics.track(.transcriptionStarted, properties: transcriptionStartedProperties)

            let transcriptionStart = Date()
            let transcriptionResult = try await transcriptionService.transcribe(audioArray: audioResult.samples, language: language)
            let transcriptionDuration = Date().timeIntervalSince(transcriptionStart)
            logInfo("Transcription successful: '\(transcriptionResult.text)'", category: .app)
            let wordCount = transcriptionResult.text.split(separator: " ").count

            // Apply custom prompt if profile has one
            var processedText: String?
            if let customPrompt = activeProfile?.customPrompt, !customPrompt.isEmpty {
                logInfo("Applying custom prompt from profile...", category: .app)
                processedText = await summarizationService.processWithCustomPrompt(
                    transcription: transcriptionResult.text,
                    customPrompt: customPrompt
                )
                if let processed = processedText {
                    logInfo("Custom prompt applied, processed text: '\(processed)'", category: .app)
                }
            }

            var transcriptionCompletedProperties = baseProperties
            transcriptionCompletedProperties["audio_duration_sec"] = audioResult.duration
            transcriptionCompletedProperties["transcription_duration_sec"] = transcriptionDuration
            transcriptionCompletedProperties["word_count"] = wordCount
            transcriptionCompletedProperties["detected_language"] = transcriptionResult.detectedLanguage
            transcriptionCompletedProperties["used_custom_prompt"] = processedText != nil
            transcriptionCompletedProperties["model_name"] = effectiveModelName
            analytics.track(.transcriptionCompleted, properties: transcriptionCompletedProperties)

            // Save audio file
            failureStage = "audio_save"
            let (audioFileName, fileSize) = try AudioFileManager.shared.saveAudio(
                audioResult.samples,
                sampleRate: audioResult.sampleRate
            )
            logInfo("Audio saved: \(audioFileName), size: \(fileSize) bytes", category: .app)

            // Create and save recording to database immediately (without summaries)
            failureStage = "database_insert"
            var recording = Recording(
                title: "",
                transcriptionText: transcriptionResult.text,
                oneLiner: nil,
                summary: nil,
                audioFileName: audioFileName,
                createdAt: Date(),
                duration: audioResult.duration,
                detectedLanguage: transcriptionResult.detectedLanguage,
                wordCount: wordCount,
                modelUsed: effectiveModelName,
                fileSize: fileSize,
                profileId: activeProfile?.id,
                processedText: processedText
            )
            recording.generateDefaultTitle()

            try RecordingRepository.shared.insert(&recording)
            logInfo("Recording saved to database with ID: \(recording.id ?? -1)", category: .app)

            // Generate AI summaries asynchronously (don't block the UI)
            if let recordingId = recording.id {
                Task {
                    await generateSummariesAsync(for: recordingId, text: transcriptionResult.text)
                }
            }

            // Notify UI of new recording
            newRecordingID = recording.id

            // Use processed text for display and paste if available, otherwise original
            let displayText = processedText ?? transcriptionResult.text
            lastTranscription = displayText
            state = .completed(displayText)
            logDebug("State set to .completed", category: .app)

            if settings.autoPasteEnabled {
                logDebug("Auto-paste enabled, preparing to paste...", category: .app)
                showPopup(false)

                try await Task.sleep(nanoseconds: 100_000_000)

                logDebug("Attempting to copy and paste...", category: .clipboard)
                let success = clipboardService.copyAndPaste(displayText)
                if success {
                    logInfo("Text pasted successfully", category: .clipboard)
                } else {
                    logWarning("Paste failed (accessibility?), text copied to clipboard only", category: .clipboard)
                    clipboardService.copyToClipboard(displayText)
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
            var failureProperties = baseProperties
            failureProperties["stage"] = failureStage
            let nsError = error as NSError
            failureProperties["error_domain"] = nsError.domain
            failureProperties["error_code"] = nsError.code
            if let audioDuration {
                failureProperties["audio_duration_sec"] = audioDuration
            }
            if let samplesCount {
                failureProperties["samples_count"] = samplesCount
            }
            analytics.track(.transcriptionFailed, properties: failureProperties)
            state = .error(error.localizedDescription)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.state = .idle
                self?.showPopup(false)
            }
        }
    }

    public func cancelRecording(source: RecordingTriggerSource = .unknown) async {
        logInfo("Cancelling recording...", category: .app)
        _ = try? await audioService.stopRecording()
        let activeProfile = settings.activeProfile
        let modelName = settings.resolvedModelName(for: activeProfile)
        analytics.track(.recordingCancelled, properties: analyticsContextProperties(source: source, profile: activeProfile, modelName: modelName))
        state = .idle
        showPopup(false)
        logDebug("Recording cancelled", category: .app)
    }

    /// Generates AI summaries asynchronously and updates the recording in the database
    private func generateSummariesAsync(for recordingId: Int64, text: String) async {
        logDebug("Starting async summary generation for recording \(recordingId)", category: .app)

        let (oneLiner, summary) = await summarizationService.generateSummaries(from: text)

        if let ol = oneLiner {
            logInfo("AI one-liner generated: '\(ol)'", category: .app)
        }
        if let s = summary {
            logInfo("AI summary generated: '\(s)'", category: .app)
        }

        analytics.track(.summaryGenerated, properties: [
            "one_liner_generated": oneLiner != nil,
            "summary_generated": summary != nil,
            "word_count": text.split(separator: " ").count
        ])

        // Update the recording in the database with the generated summaries
        guard var recording = RecordingRepository.shared.fetch(byId: recordingId) else {
            logWarning("Recording \(recordingId) not found for summary update", category: .app)
            return
        }

        recording.oneLiner = oneLiner
        recording.summary = summary

        do {
            try RecordingRepository.shared.update(recording)
            logInfo("Recording \(recordingId) updated with AI summaries", category: .app)
        } catch {
            logError("Failed to update recording with summaries: \(error.localizedDescription)", category: .app)
        }
    }

    private func analyticsContextProperties(
        source: RecordingTriggerSource,
        profile: TranscriptionProfile?,
        modelName: String
    ) -> [String: Any] {
        var properties: [String: Any] = [
            "source": source.rawValue,
            "model_name": modelName,
            "auto_paste_enabled": settings.autoPasteEnabled,
            "language_setting": profile?.language ?? "auto"
        ]

        if let profileId = profile?.id, let profileIdInt = Int(exactly: profileId) {
            properties["profile_id"] = profileIdInt
        }

        return properties
    }

    private func showPopup(_ show: Bool) {
        logDebug("showPopup(\(show))", category: .ui)
        isPopupVisible = show
        onShowPopup?(show)
    }

    public func reloadModel() async {
        await reloadModelIfNeeded(settings.effectiveModelName)
    }

    public func reloadModelIfNeeded(_ modelName: String) async {
        // Skip if the requested model is already loaded
        if transcriptionService.isModelLoaded && transcriptionService.loadedModelName == modelName {
            logDebug("Model '\(modelName)' already loaded, skipping reload", category: .app)
            return
        }

        logInfo("Reloading model: \(modelName)", category: .app)
        do {
            try await ensureModelLoaded(
                named: modelName,
                allowFallbackIfNeedsConfirmation: false,
                bypassDownloadConfirmation: false,
                context: "reload"
            )
            if transcriptionService.isModelLoaded && transcriptionService.loadedModelName == modelName {
                logInfo("Model reloaded successfully", category: .app)
            }
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
            try await ensureModelLoaded(
                named: model.name,
                allowFallbackIfNeedsConfirmation: false,
                bypassDownloadConfirmation: true,
                context: "confirmed download"
            )
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
