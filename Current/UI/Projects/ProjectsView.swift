import SwiftUI

struct ProjectsView: View {
    var body: some View {
        ContentUnavailableView {
            Label("No Projects", systemImage: "folder")
        } description: {
            Text("Add a project folder to get started.")
        } actions: {
            Button("Add Project") { }
                .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Projects")
    }
}
