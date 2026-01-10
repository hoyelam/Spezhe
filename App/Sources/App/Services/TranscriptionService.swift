import Foundation
import WhisperKit

@MainActor
public class TranscriptionService: ObservableObject {
    private var whisperKit: WhisperKit?
    @Published public private(set) var isModelLoaded = false
    @Published public private(set) var isLoading = false
    @Published public private(set) var loadingProgress: Double = 0
    @Published public private(set) var isWarmedUp = false
    @Published public private(set) var loadedModelName: String?

    public init() {
        logDebug("TranscriptionService initialized", category: .transcription)
    }

    public func loadModel(named modelName: String) async throws {
        logInfo("Loading model: \(modelName)", category: .transcription)
        isLoading = true
        loadingProgress = 0
        isWarmedUp = false

        let startTime = Date()

        do {
            logDebug("Creating WhisperKitConfig...", category: .transcription)
            let config = WhisperKitConfig(
                model: modelName,
                verbose: true,
                prewarm: false,  // Skip prewarm - CoreML compiles on first use and caches
                load: true
            )

            logDebug("Initializing WhisperKit (this may download the model)...", category: .transcription)
            whisperKit = try await WhisperKit(config)

            let loadTime = Date().timeIntervalSince(startTime)
            isModelLoaded = true
            loadedModelName = modelName
            loadingProgress = 0.5
            logInfo("Model '\(modelName)' loaded in \(String(format: "%.2f", loadTime)) seconds, starting warm-up...", category: .transcription)

            // Warm up the model with a short silent audio to force CoreML compilation
            await warmUpModel()

            let totalTime = Date().timeIntervalSince(startTime)
            loadingProgress = 1.0
            logInfo("Model '\(modelName)' fully ready in \(String(format: "%.2f", totalTime)) seconds", category: .transcription)
        } catch {
            isModelLoaded = false
            logError("Failed to load model '\(modelName)': \(error.localizedDescription)", category: .transcription)
            throw TranscriptionError.modelLoadFailed(error.localizedDescription)
        }

        isLoading = false
    }

    private func warmUpModel() async {
        guard let whisperKit = whisperKit else { return }

        logDebug("Warming up model with silent audio...", category: .transcription)
        let warmUpStartTime = Date()

        // Create 1 second of silence at 16kHz
        let silentAudio = [Float](repeating: 0.0, count: 16000)

        do {
            // Run a transcription to compile the CoreML model
            _ = try await whisperKit.transcribe(audioArray: silentAudio)
            let warmUpTime = Date().timeIntervalSince(warmUpStartTime)
            isWarmedUp = true
            logInfo("Model warm-up completed in \(String(format: "%.2f", warmUpTime)) seconds", category: .transcription)
        } catch {
            // Warm-up might fail on silent audio, but that's OK - the model is still compiled
            let warmUpTime = Date().timeIntervalSince(warmUpStartTime)
            isWarmedUp = true
            logDebug("Model warm-up finished in \(String(format: "%.2f", warmUpTime)) seconds (expected for silent audio)", category: .transcription)
        }
    }

    public func transcribe(audioArray: [Float], language: String? = nil) async throws -> TranscriptionResult {
        logInfo("Starting transcription...", category: .transcription)

        guard let whisperKit = whisperKit else {
            logError("Transcription failed: Model not loaded", category: .transcription)
            throw TranscriptionError.modelNotLoaded
        }

        guard !audioArray.isEmpty else {
            logError("Transcription failed: Empty audio array", category: .transcription)
            throw TranscriptionError.emptyAudio
        }

        let audioDuration = Double(audioArray.count) / 16000.0
        logDebug("Audio to transcribe: \(audioArray.count) samples (\(String(format: "%.2f", audioDuration)) seconds)", category: .transcription)
        logDebug("Model warmed up: \(isWarmedUp)", category: .transcription)

        // Log audio statistics for debugging
        let maxAmplitude = audioArray.map { abs($0) }.max() ?? 0
        let avgAmplitude = audioArray.map { abs($0) }.reduce(0, +) / Float(audioArray.count)
        logDebug("Audio stats - Max amplitude: \(String(format: "%.4f", maxAmplitude)), Avg amplitude: \(String(format: "%.6f", avgAmplitude))", category: .transcription)

        if maxAmplitude < 0.001 {
            logWarning("Audio appears to be silent (max amplitude < 0.001)", category: .transcription)
        }

        // Determine effective language (nil or "auto" means auto-detect)
        let effectiveLanguage: String? = (language == nil || language == "auto") ? nil : language
        if let lang = effectiveLanguage {
            logInfo("Forcing transcription language: \(lang)", category: .transcription)
        } else {
            logDebug("Language will be auto-detected", category: .transcription)
        }

        let startTime = Date()

        do {
            logDebug("Calling WhisperKit.transcribe()...", category: .transcription)
            // When forcing a language, both usePrefillPrompt and usePrefillCache must be true
            // Based on WhisperKit example: https://github.com/argmaxinc/whisperkit
            let options = DecodingOptions(
                verbose: true,
                task: .transcribe,
                language: effectiveLanguage,
                usePrefillPrompt: true,  // Always true - forces task/language tokens
                usePrefillCache: true    // Always true - uses precomputed KV caches
            )
            logDebug("DecodingOptions: language=\(effectiveLanguage ?? "auto"), usePrefillPrompt=true, usePrefillCache=true", category: .transcription)
            let results = try await whisperKit.transcribe(audioArray: audioArray, decodeOptions: options)

            let transcriptionTime = Date().timeIntervalSince(startTime)
            logDebug("WhisperKit.transcribe() completed in \(String(format: "%.2f", transcriptionTime)) seconds", category: .transcription)

            logDebug("Number of result segments: \(results.count)", category: .transcription)
            for (index, result) in results.enumerated() {
                logDebug("Segment \(index): '\(result.text)'", category: .transcription)
            }

            let text = results.map { $0.text }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)

            if text.isEmpty {
                logWarning("Transcription returned empty text (no speech detected)", category: .transcription)
                throw TranscriptionError.noSpeechDetected
            }

            // Extract detected language from the first segment
            let detectedLanguage = results.first?.language
            if let lang = detectedLanguage {
                logDebug("Detected language: \(lang)", category: .transcription)
            }

            let realTimeFactor = transcriptionTime / audioDuration
            logInfo("Transcription complete: '\(text)' (RTF: \(String(format: "%.2f", realTimeFactor))x)", category: .transcription)

            return TranscriptionResult(text: text, duration: transcriptionTime, detectedLanguage: detectedLanguage)
        } catch let error as TranscriptionError {
            throw error
        } catch {
            logError("Transcription error: \(error.localizedDescription)", category: .transcription)
            logError("Error type: \(type(of: error))", category: .transcription)
            throw TranscriptionError.transcriptionFailed(error.localizedDescription)
        }
    }

    public func unloadModel() {
        logInfo("Unloading model", category: .transcription)
        whisperKit = nil
        isModelLoaded = false
        loadedModelName = nil
        isWarmedUp = false
    }
}

public enum TranscriptionError: LocalizedError {
    case modelNotLoaded
    case modelLoadFailed(String)
    case emptyAudio
    case noSpeechDetected
    case transcriptionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "No model loaded"
        case .modelLoadFailed(let reason):
            return "Failed to load model: \(reason)"
        case .emptyAudio:
            return "No audio recorded"
        case .noSpeechDetected:
            return "No speech detected"
        case .transcriptionFailed(let reason):
            return "Transcription failed: \(reason)"
        }
    }
}
