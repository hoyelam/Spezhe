import Foundation
import GRDB

public struct Recording: Codable, Identifiable, Equatable, Hashable {
    public var id: Int64?
    public var title: String
    public var transcriptionText: String
    public var oneLiner: String?
    public var summary: String?
    public var audioFileName: String
    public var createdAt: Date
    public var duration: TimeInterval
    public var detectedLanguage: String?
    public var wordCount: Int
    public var modelUsed: String
    public var fileSize: Int64
    public var profileId: Int64?

    public init(
        id: Int64? = nil,
        title: String = "",
        transcriptionText: String,
        oneLiner: String? = nil,
        summary: String? = nil,
        audioFileName: String,
        createdAt: Date = Date(),
        duration: TimeInterval,
        detectedLanguage: String? = nil,
        wordCount: Int,
        modelUsed: String,
        fileSize: Int64,
        profileId: Int64? = nil
    ) {
        self.id = id
        self.title = title
        self.transcriptionText = transcriptionText
        self.oneLiner = oneLiner
        self.summary = summary
        self.audioFileName = audioFileName
        self.createdAt = createdAt
        self.duration = duration
        self.detectedLanguage = detectedLanguage
        self.wordCount = wordCount
        self.modelUsed = modelUsed
        self.fileSize = fileSize
        self.profileId = profileId
    }

    public mutating func generateDefaultTitle() {
        if title.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
            title = "Recording \(formatter.string(from: createdAt))"
        }
    }
}

extension Recording: FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "recordings"

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
