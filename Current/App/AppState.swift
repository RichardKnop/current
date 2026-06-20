import Foundation

/// Top-level observable state shared across the app. Owns the database, stores, and top-level models.
@Observable
final class AppState {
    let database: AppDatabase
    let projectStore: ProjectStore
    let settingsStore: SettingsStore
    let providerConfigStore: ProviderConfigStore
    let projectListModel: ProjectListModel
    let settingsModel: SettingsModel

    init() {
        do {
            let db = try AppDatabase.openShared()
            let projectStore = ProjectStore(db: db)
            let service = ProjectService()
            let providerConfigStore = ProviderConfigStore(db: db)
            let keychain = KeychainService()

            self.database = db
            self.projectStore = projectStore
            self.settingsStore = SettingsStore(db: db)
            self.providerConfigStore = providerConfigStore
            self.projectListModel = ProjectListModel(store: projectStore, service: service)
            self.settingsModel = SettingsModel(configStore: providerConfigStore, keychain: keychain)

            Self.resolveBookmarks(store: projectStore, service: service)
        } catch {
            fatalError("Failed to open app database: \(error)")
        }
    }

    // MARK: Private

    /// Resolves security-scoped bookmarks for all stored projects so the app can access their folders after restart.
    private static func resolveBookmarks(store: ProjectStore, service: ProjectService) {
        guard let projects = try? store.fetchAll() else { return }
        for project in projects {
            guard let data = project.bookmarkData else { continue }
            service.resolveBookmark(data)
        }
    }
}
