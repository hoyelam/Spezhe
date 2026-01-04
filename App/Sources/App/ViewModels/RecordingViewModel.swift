import Foundation
import Combine

@MainActor
public class RecordingViewModel: ObservableObject {
    @Published public var state: RecordingState = .idle
    @Published public var audioLevel: Float = 0
    @Published public var lastTranscription: String?
    @Published public var isPopupVisible = false
    @Published public var newRecordingID: Int64?

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
        logInfo("Pre-loading model: \(settings.selectedModelName)", category: .app)
        modelLoadTask = Task {
            do {
                try await transcriptionService.loadModel(named: settings.selectedModelName)
                logInfo("Model pre-loaded successfully", category: .app)
            } catch {
                logError("Failed to pre-load model: \(error.localizedDescription)", category: .app)
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
        case .processing:
            logWarning("toggleRecording() ignored - currently processing", category: .app)
            break
        }
    }

    private func startRecording() async {
        logInfo("Starting recording flow...", category: .app)

        do {
            if !transcriptionService.isModelLoaded {
                logInfo("Model not loaded, loading now...", category: .app)
                state = .processing
                showPopup(true)
                try await transcriptionService.loadModel(named: settings.selectedModelName)
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
        logInfo("Reloading model: \(settings.selectedModelName)", category: .app)
        transcriptionService.unloadModel()
        do {
            try await transcriptionService.loadModel(named: settings.selectedModelName)
            logInfo("Model reloaded successfully", category: .app)
        } catch {
            logError("Failed to reload model: \(error.localizedDescription)", category: .app)
        }
    }
}
