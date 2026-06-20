import Foundation

@Observable
final class SettingsModel {
    // Per-provider state
    var openAIEnabled: Bool = false
    var openAIApiKey: String = ""
    var openAIDefaultModel: String = Provider.openAI.defaultModel

    var anthropicEnabled: Bool = false
    var anthropicApiKey: String = ""
    var anthropicDefaultModel: String = Provider.anthropic.defaultModel

    var errorMessage: String?

    private let configStore: ProviderConfigStore
    private let keychain: KeychainService

    init(configStore: ProviderConfigStore, keychain: KeychainService) {
        self.configStore = configStore
        self.keychain = keychain
    }

    func load() {
        do {
            let configs = try configStore.fetchAll()
            for config in configs {
                guard let provider = Provider(rawValue: config.provider) else { continue }
                switch provider {
                case .openAI:
                    openAIEnabled = config.enabled
                    openAIDefaultModel = config.defaultModel ?? Provider.openAI.defaultModel
                    openAIApiKey = (try? keychain.get(for: provider.keychainAccount)) ?? ""
                case .anthropic:
                    anthropicEnabled = config.enabled
                    anthropicDefaultModel = config.defaultModel ?? Provider.anthropic.defaultModel
                    anthropicApiKey = (try? keychain.get(for: provider.keychainAccount)) ?? ""
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save(provider: Provider) {
        do {
            guard var config = try configStore.fetch(provider: provider) else { return }
            switch provider {
            case .openAI:
                config.enabled = openAIEnabled
                config.defaultModel = openAIDefaultModel
                try saveApiKey(openAIApiKey, for: provider)
            case .anthropic:
                config.enabled = anthropicEnabled
                config.defaultModel = anthropicDefaultModel
                try saveApiKey(anthropicApiKey, for: provider)
            }
            try configStore.update(config)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Returns true if at least one provider is enabled and has an API key set.
    var hasConfiguredProvider: Bool {
        (openAIEnabled && !openAIApiKey.isEmpty) ||
        (anthropicEnabled && !anthropicApiKey.isEmpty)
    }

    // MARK: Private

    private func saveApiKey(_ key: String, for provider: Provider) throws {
        if key.isEmpty {
            try keychain.delete(for: provider.keychainAccount)
        } else {
            try keychain.set(key, for: provider.keychainAccount)
        }
    }
}
