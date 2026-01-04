import Foundation
import AVFoundation

public enum AudioFileError: Error, LocalizedError {
    case directoryCreationFailed
    case fileWriteFailed(String)
    case fileNotFound(String)
    case deletionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .directoryCreationFailed:
            return "Failed to create recordings directory"
        case .fileWriteFailed(let details):
            return "Failed to write audio file: \(details)"
        case .fileNotFound(let fileName):
            return "Audio file not found: \(fileName)"
        case .deletionFailed(let details):
            return "Failed to delete audio file: \(details)"
        }
    }
}

@MainActor
public final class AudioFileManager {
    public static let shared = AudioFileManager()

    public let recordingsDirectory: URL

    private init() {
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        recordingsDirectory = appSupportURL.appendingPathComponent("Spetra/Recordings")

        do {
            try fileManager.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
            logInfo("Recordings directory: \(recordingsDirectory.path)", category: .audio)
        } catch {
            logError("Failed to create recordings directory: \(error)", category: .audio)
        }
    }

    public func saveAudio(_ samples: [Float], sampleRate: Double = 16000) throws -> (fileName: String, fileSize: Int64) {
        let fileName = "\(UUID().uuidString).wav"
        let fileURL = recordingsDirectory.appendingPathComponent(fileName)

        try writeWAVFile(samples: samples, sampleRate: sampleRate, to: fileURL)

        let attrs = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileSize = attrs[.size] as? Int64 ?? 0

        logInfo("Saved audio file: \(fileName), size: \(fileSize) bytes", category: .audio)
        return (fileName, fileSize)
    }

    public func audioURL(for fileName: String) -> URL {
        recordingsDirectory.appendingPathComponent(fileName)
    }

    public func deleteAudio(fileName: String) throws {
        let fileURL = audioURL(for: fileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            logWarning("Audio file does not exist: \(fileName)", category: .audio)
            return
        }

        do {
            try FileManager.default.removeItem(at: fileURL)
            logInfo("Deleted audio file: \(fileName)", category: .audio)
        } catch {
            throw AudioFileError.deletionFailed(error.localizedDescription)
        }
    }

    public func fileExists(_ fileName: String) -> Bool {
        FileManager.default.fileExists(atPath: audioURL(for: fileName).path)
    }

    private func writeWAVFile(samples: [Float], sampleRate: Double, to url: URL) throws {
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        )!

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)) else {
            throw AudioFileError.fileWriteFailed("Failed to create audio buffer")
        }

        buffer.frameLength = AVAudioFrameCount(samples.count)

        if let channelData = buffer.floatChannelData?[0] {
            for (index, sample) in samples.enumerated() {
                channelData[index] = sample
            }
        }

        do {
            let audioFile = try AVAudioFile(forWriting: url, settings: format.settings)
            try audioFile.write(from: buffer)
        } catch {
            throw AudioFileError.fileWriteFailed(error.localizedDescription)
        }
    }

    public func loadWaveformSamples(from fileName: String, targetSampleCount: Int = 200) -> [Float] {
        let fileURL = audioURL(for: fileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        do {
            let audioFile = try AVAudioFile(forReading: fileURL)
            let frameCount = AVAudioFrameCount(audioFile.length)

            guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: frameCount) else {
                return []
            }

            try audioFile.read(into: buffer)

            guard let channelData = buffer.floatChannelData?[0] else {
                return []
            }

            let totalSamples = Int(buffer.frameLength)
            let samplesPerBucket = max(1, totalSamples / targetSampleCount)
            var waveformSamples: [Float] = []

            for i in 0..<targetSampleCount {
                let startIndex = i * samplesPerBucket
                let endIndex = min(startIndex + samplesPerBucket, totalSamples)

                if startIndex >= totalSamples {
                    break
                }

                var maxAmplitude: Float = 0
                for j in startIndex..<endIndex {
                    maxAmplitude = max(maxAmplitude, abs(channelData[j]))
                }
                waveformSamples.append(maxAmplitude)
            }

            return waveformSamples
        } catch {
            logError("Failed to load waveform samples: \(error)", category: .audio)
            return []
        }
    }
}
