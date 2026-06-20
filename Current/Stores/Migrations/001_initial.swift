import Foundation
import GRDB

enum Migration001Initial {
    static func register(in migrator: inout DatabaseMigrator) {
        migrator.registerMigration("001_initial") { db in
            try db.create(table: "projects") { t in
                t.primaryKey("id", .text)
                t.column("name", .text).notNull()
                t.column("folder_path", .text).notNull().unique()
                t.column("bookmark_data", .blob)
                t.column("git_enabled", .integer).notNull().defaults(to: 0)
                t.column("created_at", .text).notNull()
                t.column("last_opened_at", .text)
            }

            try db.create(table: "app_settings") { t in
                t.primaryKey("key", .text)
                t.column("value", .text).notNull()
            }

            try db.create(table: "provider_configs") { t in
                t.primaryKey("id", .text)
                t.column("provider", .text).notNull()
                t.column("enabled", .integer).notNull().defaults(to: 0)
                t.column("default_model", .text)
                t.column("created_at", .text).notNull()
            }

            // Seed default provider config rows so settings page can toggle them.
            let now = ISO8601DateFormatter().string(from: .now)
            try db.execute(
                sql: """
                INSERT INTO provider_configs (id, provider, enabled, created_at)
                VALUES (?, 'openai', 0, ?), (?, 'anthropic', 0, ?)
                """,
                arguments: [UUID().uuidString, now, UUID().uuidString, now]
            )
        }
    }
}
