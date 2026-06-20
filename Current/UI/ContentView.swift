import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var sidebarSelection: SidebarDestination? = .projects
    @State private var selectedProject: ProjectRecord?

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $sidebarSelection)
        } content: {
            switch sidebarSelection {
            case .projects:
                ProjectsView(selectedProject: $selectedProject)
            case .library:
                LibraryView()
            case .prompts:
                PromptsView()
            case nil:
                EmptyView()
            }
        } detail: {
            if let project = selectedProject {
                ProjectDetailView(project: project)
            } else {
                Text("Select a project")
                    .foregroundStyle(.secondary)
            }
        }
        .onAppear {
            appState.projectListModel.load()
        }
    }
}
