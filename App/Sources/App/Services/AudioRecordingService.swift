@preconcurrency import AVFoundation
import Combine

public struct AudioRecordingResult {
    public let samples: [Float]
    public let duration: TimeInterval
    public let sampleRate: Double

    public init(samples: [Float], duration: TimeInterval, sampleRate: Double = 16000) {
        self.samples = samples
        self.duration = duration
        self.sampleRate = sampleRate
    }
}

@MainActor
public class AudioRecordingService: ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var audioBuffer: [Float] = []
    private var levelUpdateTimer: Timer?
    private var sampleCount: Int = 0
    private var recordingStartTime: Date?
    private var hasInstalledTap = false
    private let targetSampleRate: Double = 16000

    @Published public var audioLevel: Float = 0
    @Published public private(set) var isRecording = false

    public init() {
        logDebug("AudioRecordingService initialized", category: .audio)
    }

    public func startRecording() async throws {
        logInfo("Starting recording...", category: .audio)

        let granted = await requestMicrophonePermission()
        guard granted else {
            logError("Microphone permission denied", category: .audio)
            throw AudioRecordingError.permissionDenied
        }
        logDebug("Microphone permission granted", category: .audio)

        hasInstalledTap = false
        audioBuffer = []
        sampleCount = 0
        recordingStartTime = Date()
        audioEngine = AVAudioEngine()

        guard let audioEngine = audioEngine else {
            logError("Failed to create AVAudioEngine", category: .audio)
            throw AudioRecordingError.engineInitFailed
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        logDebug("Input format: \(recordingFormat.sampleRate)Hz, \(recordingFormat.channelCount) channels", category: .audio)

        guard recordingFormat.channelCount > 0, recordingFormat.sampleRate > 0 else {
            logError("No valid audio input device detected", category: .audio)
            throw AudioRecordingError.noInputDevice
        }

        guard let targetFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: targetSampleRate, channels: 1, interleaved: false) else {
            logError("Failed to create target audio format", category: .audio)
            throw AudioRecordingError.converterInitFailed
        }

        guard let converter = AVAudioConverter(from: recordingFormat, to: targetFormat) else {
            logError("Failed to create audio converter from \(recordingFormat) to \(targetFormat)", category: .audio)
            throw AudioRecordingError.converterInitFailed
        }
        logDebug("Audio converter created: \(recordingFormat.sampleRate)Hz -> \(targetSampleRate)Hz", category: .audio)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, time in
            guard let self = self else { return }

            let level = self.calculateLevel(buffer: buffer)
            Task { @MainActor in
                self.audioLevel = level
            }

            let frameCount = AVAudioFrameCount(Double(buffer.frameLength) * targetSampleRate / recordingFormat.sampleRate)
            guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: converter.outputFormat, frameCapacity: frameCount) else {
                logWarning("Failed to create converted buffer", category: .audio)
                return
            }

            var error: NSError?
            let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }

            converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)

            if let error = error {
                logWarning("Conversion error: \(error.localizedDescription)", category: .audio)
            }

            if let channelData = convertedBuffer.floatChannelData?[0] {
                let samples = Array(UnsafeBufferPointer(start: channelData, count: Int(convertedBuffer.frameLength)))
                Task { @MainActor in
                    self.audioBuffer.append(contentsOf: samples)
                    self.sampleCount += samples.count
                    if self.sampleCount % 16000 == 0 {
                        logDebug("Recorded \(self.sampleCount / 16000) seconds (\(self.audioBuffer.count) samples)", category: .audio)
                    }
                }
            }
        }
        hasInstalledTap = true
        logDebug("Audio tap installed", category: .audio)

        do {
            try audioEngine.start()
            isRecording = true
            logInfo("Recording started successfully", category: .audio)
        } catch {
            logError("Failed to start audio engine: \(error.localizedDescription)", category: .audio)
            throw AudioRecordingError.engineInitFailed
        }
    }

    public func stopRecording() async throws -> AudioRecordingResult {
        logInfo("Stopping recording...", category: .audio)

        if let audioEngine {
            if hasInstalledTap {
                audioEngine.inputNode.removeTap(onBus: 0)
                hasInstalledTap = false
            }
            audioEngine.stop()
            self.audioEngine = nil
        }
        isRecording = false
        audioLevel = 0

        let buffer = audioBuffer
        let duration = Double(buffer.count) / targetSampleRate
        audioBuffer = []
        sampleCount = 0
        recordingStartTime = nil

        logInfo("Recording stopped. Captured \(buffer.count) samples (\(String(format: "%.2f", duration)) seconds)", category: .audio)

        if buffer.isEmpty {
            logWarning("Audio buffer is empty!", category: .audio)
        }

        return AudioRecordingResult(samples: buffer, duration: duration, sampleRate: targetSampleRate)
    }

    private func calculateLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }

        let channelDataArray = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
        let rms = sqrt(channelDataArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))

        let minDb: Float = -60
        let maxDb: Float = 0
        let db = 20 * log10(max(rms, 0.0001))
        let normalized = (db - minDb) / (maxDb - minDb)

        return max(0, min(1, normalized))
    }

    private func requestMicrophonePermission() async -> Bool {
        logDebug("Requesting microphone permission...", category: .audio)
        return await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}

public enum AudioRecordingError: LocalizedError {
    case permissionDenied
    case noInputDevice
    case engineInitFailed
    case converterInitFailed

    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission denied"
        case .noInputDevice:
            return "No audio input device available"
        case .engineInitFailed:
            return "Failed to initialize audio engine"
        case .converterInitFailed:
            return "Failed to initialize audio converter"
        }
    }
}
