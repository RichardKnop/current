import Foundation
import GRDB

final class ProviderConfigStore {
    private let db: AppDatabase

    init(db: AppDatabase) {
        self.db = db
    }

    func fetchAll() throws -> [ProviderConfigRecord] {
        try db.dbQueue.read { db in
            try ProviderConfigRecord.fetchAll(db)
        }
    }

    func fetch(provider: Provider) throws -> ProviderConfigRecord? {
        try db.dbQueue.read { db in
            try ProviderConfigRecord
                .filter(Column("provider") == provider.rawValue)
                .fetchOne(db)
        }
    }

    func update(_ config: ProviderConfigRecord) throws {
        try db.dbQueue.write { db in
            try config.update(db)
        }
    }
}
