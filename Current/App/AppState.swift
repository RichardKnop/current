import Foundation

/// Top-level observable state shared across the app. Owns the database and stores.
@Observable
final class AppState {
    let database: AppDatabase
    let projectStore: ProjectStore
    let settingsStore: SettingsStore

    init() {
        do {
            let db = try AppDatabase.openShared()
            self.database = db
            self.projectStore = ProjectStore(db: db)
            self.settingsStore = SettingsStore(db: db)
        } catch {
            fatalError("Failed to open app database: \(error)")
        }
    }
}
