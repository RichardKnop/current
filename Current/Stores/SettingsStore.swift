import Foundation
import GRDB

final class SettingsStore {
    private let db: AppDatabase

    init(db: AppDatabase) {
        self.db = db
    }

    func value(for key: String) throws -> String? {
        try db.dbQueue.read { db in
            try String.fetchOne(db, sql: "SELECT value FROM app_settings WHERE key = ?", arguments: [key])
        }
    }

    func setValue(_ value: String, for key: String) throws {
        try db.dbQueue.write { db in
            try db.execute(
                sql: "INSERT INTO app_settings (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value",
                arguments: [key, value]
            )
        }
    }
}
