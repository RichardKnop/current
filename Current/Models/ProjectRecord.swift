import Foundation
import GRDB

struct ProjectRecord: Codable, FetchableRecord, PersistableRecord, Identifiable, Equatable, Hashable {
    static let databaseTableName = "projects"

    var id: String
    var name: String
    var folderPath: String
    var bookmarkData: Data?
    var gitEnabled: Bool
    var createdAt: String
    var lastOpenedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case folderPath = "folder_path"
        case bookmarkData = "bookmark_data"
        case gitEnabled = "git_enabled"
        case createdAt = "created_at"
        case lastOpenedAt = "last_opened_at"
    }

    static func new(name: String, folderPath: String, bookmarkData: Data?, gitEnabled: Bool) -> ProjectRecord {
        ProjectRecord(
            id: UUID().uuidString,
            name: name,
            folderPath: folderPath,
            bookmarkData: bookmarkData,
            gitEnabled: gitEnabled,
            createdAt: ISO8601DateFormatter().string(from: .now),
            lastOpenedAt: nil
        )
    }
}
