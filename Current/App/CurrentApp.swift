import SwiftUI

@main
struct CurrentApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1100, height: 700)

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}
