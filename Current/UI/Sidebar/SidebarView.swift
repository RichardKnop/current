import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarDestination?

    var body: some View {
        List(selection: $selection) {
            Label("Projects", systemImage: "folder")
                .tag(SidebarDestination.projects)

            Label("Library", systemImage: "books.vertical")
                .tag(SidebarDestination.library)

            Label("Prompts", systemImage: "text.bubble")
                .tag(SidebarDestination.prompts)
        }
        .navigationTitle(AppInfo.displayName)
        .listStyle(.sidebar)
    }
}
