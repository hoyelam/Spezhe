import Foundation

@MainActor
public final class RecordingRetentionService {
    public static let shared = RecordingRetentionService()

    private init() {}

    public func enforceLimit() {
        let limitGB = AppSettings.shared.recordingStorageLimitGB
        let limitBytes = Int64(limitGB) * 1024 * 1024 * 1024
        guard limitBytes > 0 else { return }

        let recordings = RecordingRepository.shared.fetchAll().sorted { $0.createdAt < $1.createdAt }
        guard !recordings.isEmpty else { return }

        var sizes: [Int64] = []
        sizes.reserveCapacity(recordings.count)

        var totalBytes: Int64 = 0
        for recording in recordings {
            let size = fileSizeOnDisk(for: recording.audioFileName)
            sizes.append(size)
            totalBytes += size
        }

        guard totalBytes > limitBytes else { return }

        var deletedCount = 0
        var freedBytes: Int64 = 0

        for (index, recording) in recordings.enumerated() {
            if totalBytes <= limitBytes {
                break
            }

            let fileSize = sizes[index]
            guard fileSize > 0 else { continue }

            do {
                try AudioFileManager.shared.deleteAudio(fileName: recording.audioFileName)
                totalBytes -= fileSize
                freedBytes += fileSize
                deletedCount += 1
            } catch {
                logError("Failed to delete audio file \(recording.audioFileName): \(error)", category: .audio)
            }
        }

        if deletedCount > 0 {
            logInfo(
                "Storage limit enforced: deleted \(deletedCount) audio files, freed \(freedBytes) bytes",
                category: .audio
            )
        }
    }

    private func fileSizeOnDisk(for fileName: String) -> Int64 {
        let fileURL = AudioFileManager.shared.audioURL(for: fileName)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return 0
        }

        let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
        return attrs?[.size] as? Int64 ?? 0
    }
}
