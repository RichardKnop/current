import SwiftUI

struct SettingsView: View {
    private enum Tab: String {
        case providers
        case general
    }

    @State private var selectedTab: Tab = .providers

    var body: some View {
        TabView(selection: $selectedTab) {
            ProvidersSettingsView()
                .tabItem { Label("Providers", systemImage: "cpu") }
                .tag(Tab.providers)

            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }
                .tag(Tab.general)
        }
        .frame(width: 500, height: 320)
    }
}

private struct ProvidersSettingsView: View {
    var body: some View {
        Form {
            Section("API Keys") {
                Text("Provider configuration is coming in a later phase.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

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
