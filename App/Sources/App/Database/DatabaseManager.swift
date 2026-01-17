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
            let appSupportDir = appSupportURL.appendingPathComponent(Constants.appSupportDirectory)
            let legacyAppSupportDir = appSupportURL.appendingPathComponent(Constants.legacyAppSupportDirectory)

            if !fileManager.fileExists(atPath: appSupportDir.path),
               fileManager.fileExists(atPath: legacyAppSupportDir.path) {
                do {
                    try fileManager.moveItem(at: legacyAppSupportDir, to: appSupportDir)
                } catch {
                    logWarning("Failed to migrate legacy app support directory: \(error)", category: .app)
                }
            }

            try fileManager.createDirectory(at: appSupportDir, withIntermediateDirectories: true)

            let dbURL = appSupportDir.appendingPathComponent(Constants.databaseFileName)
            let legacyDbURL = legacyAppSupportDir.appendingPathComponent(Constants.legacyDatabaseFileName)
            let legacyDbURLInNewDir = appSupportDir.appendingPathComponent(Constants.legacyDatabaseFileName)

            if !fileManager.fileExists(atPath: dbURL.path) {
                if fileManager.fileExists(atPath: legacyDbURLInNewDir.path) {
                    do {
                        try fileManager.moveItem(at: legacyDbURLInNewDir, to: dbURL)
                    } catch {
                        logWarning("Failed to migrate legacy database file: \(error)", category: .app)
                    }
                } else if fileManager.fileExists(atPath: legacyDbURL.path) {
                    do {
                        try fileManager.moveItem(at: legacyDbURL, to: dbURL)
                    } catch {
                        logWarning("Failed to migrate legacy database file: \(error)", category: .app)
                    }
                }
            }

            dbQueue = try DatabaseQueue(path: dbURL.path)

            runMigrations()

            logInfo("Database initialized at: \(dbURL.path)", category: .app)
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
