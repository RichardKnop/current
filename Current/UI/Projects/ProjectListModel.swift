import Foundation

@Observable
final class ProjectListModel {
    private(set) var projects: [ProjectRecord] = []
    var errorMessage: String?

    private let store: ProjectStore
    private let service: ProjectService

    init(store: ProjectStore, service: ProjectService) {
        self.store = store
        self.service = service
    }

    func load() {
        do {
            projects = try store.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func addExistingFolder() async {
        guard let url = service.pickFolder(canCreate: false) else { return }
        await createProject(name: url.lastPathComponent, url: url)
    }

    @MainActor
    func createNewFolder() async {
        guard let url = service.pickFolder(canCreate: true) else { return }
        // The user may have created a subdirectory; use whatever they selected.
        await createProject(name: url.lastPathComponent, url: url)
    }

    func delete(_ project: ProjectRecord) {
        do {
            try store.delete(id: project.id)
            projects.removeAll { $0.id == project.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markOpened(_ project: ProjectRecord) {
        // Update last_opened_at in the DB so the order is correct on next launch,
        // but don't reload the list — reordering while the user is clicking is jarring.
        try? store.updateLastOpened(id: project.id)
    }

    // MARK: Private

    private func createProject(name: String, url: URL) async {
        do {
            let record = try service.createProject(name: name, url: url)
            try store.insert(record)
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
