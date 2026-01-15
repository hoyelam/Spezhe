import Foundation
import GRDB
import Combine

@MainActor
public final class ProfileRepository: ObservableObject {
    public static let shared = ProfileRepository()

    @Published public private(set) var profiles: [TranscriptionProfile] = []

    private var cancellable: AnyCancellable?

    private init() {
        observeProfiles()
    }

    private func observeProfiles() {
        let observation = ValueObservation.tracking { db in
            try TranscriptionProfile.order(Column("name").asc).fetchAll(db)
        }

        cancellable = observation
            .publisher(in: DatabaseManager.shared.dbQueue, scheduling: .immediate)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        logError("Profile observation error: \(error)", category: .app)
                    }
                },
                receiveValue: { [weak self] profiles in
                    self?.profiles = profiles
                }
            )
    }

    public func insert(_ profile: inout TranscriptionProfile) throws {
        try DatabaseManager.shared.dbQueue.write { db in
            try profile.insert(db)
        }
        logInfo("Inserted profile: \(profile.name)", category: .app)
    }

    public func update(_ profile: TranscriptionProfile) throws {
        var updatedProfile = profile
        updatedProfile.updatedAt = Date()
        try DatabaseManager.shared.dbQueue.write { db in
            try updatedProfile.update(db)
        }
        logInfo("Updated profile: \(profile.name)", category: .app)
    }

    public func delete(_ profile: TranscriptionProfile) throws {
        guard let id = profile.id else { return }
        try DatabaseManager.shared.dbQueue.write { db in
            _ = try TranscriptionProfile.deleteOne(db, id: id)
        }
        logInfo("Deleted profile: \(profile.name)", category: .app)
    }

    public func fetchAll() -> [TranscriptionProfile] {
        do {
            return try DatabaseManager.shared.dbQueue.read { db in
                try TranscriptionProfile.order(Column("name").asc).fetchAll(db)
            }
        } catch {
            logError("Failed to fetch profiles: \(error)", category: .app)
            return []
        }
    }

    public func fetch(byId id: Int64) -> TranscriptionProfile? {
        do {
            return try DatabaseManager.shared.dbQueue.read { db in
                try TranscriptionProfile.fetchOne(db, id: id)
            }
        } catch {
            logError("Failed to fetch profile by id: \(error)", category: .app)
            return nil
        }
    }

    public func clearModelOverrides(named modelName: String) throws -> Int {
        let updatedAt = Date()
        let updatedCount = try DatabaseManager.shared.dbQueue.write { db in
            try db.execute(
                sql: """
                UPDATE transcription_profiles
                SET modelName = NULL, updatedAt = ?
                WHERE modelName = ?
                """,
                arguments: [updatedAt, modelName]
            )
            return db.changesCount
        }

        if updatedCount > 0 {
            logInfo("Cleared model override '\(modelName)' for \(updatedCount) profile(s)", category: .app)
        }

        return updatedCount
    }
}
