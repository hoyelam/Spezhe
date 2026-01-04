import Foundation
import GRDB

struct AppMigrations {
    static func registerMigrations(_ migrator: inout DatabaseMigrator) {
        migrator.registerMigration("v1_createRecordings") { db in
            try db.create(table: "recordings") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("title", .text).notNull()
                t.column("transcriptionText", .text).notNull()
                t.column("audioFileName", .text).notNull().unique()
                t.column("createdAt", .datetime).notNull().indexed()
                t.column("duration", .double).notNull()
                t.column("detectedLanguage", .text)
                t.column("wordCount", .integer).notNull()
                t.column("modelUsed", .text).notNull()
                t.column("fileSize", .integer).notNull()
            }
        }
    }
}
