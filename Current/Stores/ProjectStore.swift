import Foundation
import GRDB

final class ProjectStore {
    private let db: AppDatabase

    init(db: AppDatabase) {
        self.db = db
    }

    func fetchAll() throws -> [ProjectRecord] {
        try db.dbQueue.read { db in
            try ProjectRecord.fetchAll(db)
        }
    }

    func insert(_ project: ProjectRecord) throws {
        try db.dbQueue.write { db in
            try project.insert(db)
        }
    }

    func delete(id: String) throws {
        try db.dbQueue.write { db in
            try db.execute(sql: "DELETE FROM projects WHERE id = ?", arguments: [id])
        }
    }

    func updateLastOpened(id: String) throws {
        let now = ISO8601DateFormatter().string(from: .now)
        try db.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE projects SET last_opened_at = ? WHERE id = ?",
                arguments: [now, id]
            )
        }
    }
}
