import Foundation
import GRDB

struct ProviderConfigRecord: Codable, FetchableRecord, PersistableRecord, Identifiable {
    static let databaseTableName = "provider_configs"

    var id: String
    var provider: String
    var enabled: Bool
    var defaultModel: String?
    var createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case provider
        case enabled
        case defaultModel = "default_model"
        case createdAt = "created_at"
    }
}

/// Well-known provider identifiers.
enum Provider: String, CaseIterable {
    case openAI = "openai"
    case anthropic = "anthropic"

    var displayName: String {
        switch self {
        case .openAI: return "OpenAI"
        case .anthropic: return "Anthropic"
        }
    }

    var keychainAccount: String { "api_key_\(rawValue)" }

    var models: [String] {
        switch self {
        case .openAI:
            return ["gpt-4o", "gpt-4o-mini", "gpt-4-turbo", "gpt-3.5-turbo"]
        case .anthropic:
            return ["claude-opus-4-5", "claude-sonnet-4-5", "claude-haiku-3-5"]
        }
    }

    var defaultModel: String { models[0] }
}
