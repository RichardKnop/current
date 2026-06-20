import Foundation
import GRDB

/// Central database handle. Created once at app startup and injected into stores.
final class AppDatabase {
    let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    /// Opens (or creates) the database at the standard Application Support location.
    static func openShared() throws -> AppDatabase {
        let fm = FileManager.default
        let support = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dbDir = support.appendingPathComponent(Bundle.main.bundleIdentifier ?? "current", isDirectory: true)
        try fm.createDirectory(at: dbDir, withIntermediateDirectories: true)
        let dbURL = dbDir.appendingPathComponent("app.sqlite")
        var config = Configuration()
        config.prepareDatabase { db in
            db.trace(options: .profile) { event in
                // Uncomment during debugging:
                // print("[db]", event)
            }
        }
        let queue = try DatabaseQueue(path: dbURL.path, configuration: config)
        let db = AppDatabase(dbQueue: queue)
        try db.runMigrations()
        return db
    }

    private func runMigrations() throws {
        var migrator = DatabaseMigrator()
        Migration001Initial.register(in: &migrator)
        try migrator.migrate(dbQueue)
    }
}
