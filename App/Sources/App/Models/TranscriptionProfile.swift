import Foundation
import GRDB

public struct TranscriptionProfile: Codable, Identifiable, Equatable, Hashable {
    public var id: Int64?
    public var name: String
    public var modelName: String?
    public var language: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: Int64? = nil,
        name: String,
        modelName: String? = nil,
        language: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.modelName = modelName
        self.language = language
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension TranscriptionProfile: FetchableRecord, MutablePersistableRecord {
    public static let databaseTableName = "transcription_profiles"

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
