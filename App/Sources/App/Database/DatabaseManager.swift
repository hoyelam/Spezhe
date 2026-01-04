import Foundation
import GRDB

@MainActor
public final class DatabaseManager {
    public static let shared = DatabaseManager()

    public private(set) var dbQueue: DatabaseQueue!

    private init() {
        setupDatabase()
    }

    private func setupDatabase() {
        do {
            let fileManager = FileManager.default
            let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let spetraDir = appSupportURL.appendingPathComponent("Spetra")

            try fileManager.createDirectory(at: spetraDir, withIntermediateDirectories: true)

            let dbPath = spetraDir.appendingPathComponent("spetra.sqlite").path
            dbQueue = try DatabaseQueue(path: dbPath)

            runMigrations()

            logInfo("Database initialized at: \(dbPath)", category: .app)
        } catch {
            logError("Failed to setup database: \(error)", category: .app)
            fatalError("Database setup failed: \(error)")
        }
    }

    private func runMigrations() {
        do {
            var migrator = DatabaseMigrator()
            AppMigrations.registerMigrations(&migrator)
            try migrator.migrate(dbQueue)
            logInfo("Database migrations completed", category: .app)
        } catch {
            logError("Database migration failed: \(error)", category: .app)
            fatalError("Database migration failed: \(error)")
        }
    }
}
