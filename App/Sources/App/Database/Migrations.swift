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

        migrator.registerMigration("v2_addAISummaryColumns") { db in
            try db.alter(table: "recordings") { t in
                t.add(column: "oneLiner", .text)
                t.add(column: "summary", .text)
            }
        }

        migrator.registerMigration("v3_addTranscriptionProfiles") { db in
            try db.create(table: "transcription_profiles") { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("name", .text).notNull()
                t.column("modelName", .text)
                t.column("language", .text)
                t.column("customPrompt", .text)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }

            try db.alter(table: "recordings") { t in
                t.add(column: "profileId", .integer).references("transcription_profiles", onDelete: .setNull)
                t.add(column: "processedText", .text)
            }
        }

        migrator.registerMigration("v4_removeAnthropicProcessingColumns") { db in
            try db.alter(table: "transcription_profiles") { t in
                t.drop(column: "customPrompt")
            }

            try db.alter(table: "recordings") { t in
                t.drop(column: "processedText")
            }
        }
    }
}
