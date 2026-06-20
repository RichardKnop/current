import SwiftUI

struct SettingsView: View {
    @Environment(SettingsModel.self) private var model

    var body: some View {
        TabView {
            ProvidersSettingsView()
                .tabItem { Label("Providers", systemImage: "cpu") }

            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }
        }
        .frame(width: 520, height: 360)
        .onAppear { model.load() }
        .alert("Error", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK") { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }
}

// MARK: - Providers tab

private struct ProvidersSettingsView: View {
    @Environment(SettingsModel.self) private var model

    var body: some View {
        Form {
            ProviderSectionView(
                provider: .openAI,
                enabled: Binding(get: { model.openAIEnabled }, set: { model.openAIEnabled = $0 }),
                apiKey: Binding(get: { model.openAIApiKey }, set: { model.openAIApiKey = $0 }),
                selectedModel: Binding(get: { model.openAIDefaultModel }, set: { model.openAIDefaultModel = $0 })
            )

            ProviderSectionView(
                provider: .anthropic,
                enabled: Binding(get: { model.anthropicEnabled }, set: { model.anthropicEnabled = $0 }),
                apiKey: Binding(get: { model.anthropicApiKey }, set: { model.anthropicApiKey = $0 }),
                selectedModel: Binding(get: { model.anthropicDefaultModel }, set: { model.anthropicDefaultModel = $0 })
            )
        }
        .formStyle(.grouped)
    }
}

private struct ProviderSectionView: View {
    @Environment(SettingsModel.self) private var model

    let provider: Provider
    @Binding var enabled: Bool
    @Binding var apiKey: String
    @Binding var selectedModel: String

    var body: some View {
        Section {
            Toggle("Enable \(provider.displayName)", isOn: $enabled)
                .onChange(of: enabled) { _, _ in model.save(provider: provider) }

            if enabled {
                SecureField("API Key", text: $apiKey, prompt: Text("\(provider.displayName) API key"))
                    .onSubmit { model.save(provider: provider) }

                Picker("Default model", selection: $selectedModel) {
                    ForEach(provider.models, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .onChange(of: selectedModel) { _, _ in model.save(provider: provider) }

                HStack(spacing: 6) {
                    Image(systemName: apiKey.isEmpty ? "exclamationmark.circle" : "checkmark.circle.fill")
                        .foregroundStyle(apiKey.isEmpty ? AnyShapeStyle(.secondary) : AnyShapeStyle(Color.green))
                    Text(apiKey.isEmpty ? "API key not configured" : "API key saved")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text(provider.displayName)
        }
    }
}

// MARK: - General tab

private struct GeneralSettingsView: View {
    var body: some View {
        Form {
            Section {
                Text("General preferences are coming in a later phase.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}
