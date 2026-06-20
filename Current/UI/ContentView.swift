import SwiftUI

struct ContentView: View {
    @State private var selection: SidebarDestination? = .projects

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
        } detail: {
            switch selection {
            case .projects:
                ProjectsView()
            case .library:
                LibraryView()
            case .prompts:
                PromptsView()
            case nil:
                Text("Select an item from the sidebar")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
