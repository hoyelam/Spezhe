import Foundation
import GRDB
import Combine

@MainActor
public final class RecordingRepository: ObservableObject {
    public static let shared = RecordingRepository()

    @Published public private(set) var recordings: [Recording] = []

    private var cancellable: AnyCancellable?

    private init() {
        observeRecordings()
    }

    private func observeRecordings() {
        let observation = ValueObservation.tracking { db in
            try Recording.order(Column("createdAt").desc).fetchAll(db)
        }

        cancellable = observation
            .publisher(in: DatabaseManager.shared.dbQueue, scheduling: .immediate)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        logError("Database observation error: \(error)", category: .app)
                    }
                },
                receiveValue: { [weak self] recordings in
                    self?.recordings = recordings
                }
            )
    }

    public func insert(_ recording: inout Recording) throws {
        try DatabaseManager.shared.dbQueue.write { db in
            try recording.insert(db)
        }
        logInfo("Inserted recording: \(recording.title)", category: .app)
    }

    public func update(_ recording: Recording) throws {
        try DatabaseManager.shared.dbQueue.write { db in
            try recording.update(db)
        }
        logInfo("Updated recording: \(recording.title)", category: .app)
    }

    public func delete(_ recording: Recording) throws {
        guard let id = recording.id else { return }
        try DatabaseManager.shared.dbQueue.write { db in
            _ = try Recording.deleteOne(db, id: id)
        }
        logInfo("Deleted recording: \(recording.title)", category: .app)
    }

    public func fetchAll() -> [Recording] {
        do {
            return try DatabaseManager.shared.dbQueue.read { db in
                try Recording.order(Column("createdAt").desc).fetchAll(db)
            }
        } catch {
            logError("Failed to fetch recordings: \(error)", category: .app)
            return []
        }
    }

    public func fetch(byId id: Int64) -> Recording? {
        do {
            return try DatabaseManager.shared.dbQueue.read { db in
                try Recording.fetchOne(db, id: id)
            }
        } catch {
            logError("Failed to fetch recording by id: \(error)", category: .app)
            return nil
        }
    }
}
