import AppKit
import Foundation

final class ProjectService {
    /// Creates a new project record for the given folder URL, capturing a security-scoped bookmark.
    func createProject(name: String, url: URL) throws -> ProjectRecord {
        let bookmarkData = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        let gitEnabled = FileManager.default.fileExists(
            atPath: url.appending(path: ".git", directoryHint: .isDirectory).path(percentEncoded: false)
        )
        return ProjectRecord.new(
            name: name,
            folderPath: url.path(percentEncoded: false),
            bookmarkData: bookmarkData,
            gitEnabled: gitEnabled
        )
    }

    /// Resolves stored bookmark data back to a URL and begins accessing the security-scoped resource.
    /// Returns the resolved URL, or nil if resolution fails.
    @discardableResult
    func resolveBookmark(_ data: Data) -> URL? {
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: data,
            options: .withSecurityScope,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else { return nil }
        _ = url.startAccessingSecurityScopedResource()
        return url
    }

    /// Opens an NSOpenPanel for the user to pick a folder.
    /// - Parameter canCreate: when true, the panel lets the user create a new folder.
    @MainActor
    func pickFolder(canCreate: Bool) -> URL? {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = canCreate
        panel.allowsMultipleSelection = false
        panel.prompt = canCreate ? "Create" : "Open"
        panel.message = canCreate ? "Choose where to create the new project folder" : "Select an existing project folder"
        guard panel.runModal() == .OK else { return nil }
        return panel.url
    }
}
