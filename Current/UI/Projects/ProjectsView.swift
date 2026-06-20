import SwiftUI

struct ProjectsView: View {
    @Environment(ProjectListModel.self) private var model
    @Binding var selectedProject: ProjectRecord?

    var body: some View {
        Group {
            if model.projects.isEmpty {
                ContentUnavailableView {
                    Label("No Projects", systemImage: "folder")
                } description: {
                    Text("Add a project folder to get started.")
                } actions: {
                    addMenu
                }
            } else {
                List(model.projects, id: \.id, selection: $selectedProject) { project in
                    ProjectRowView(project: project)
                        .tag(project)
                }
                .listStyle(.inset)
                .onChange(of: selectedProject) { _, new in
                    if let p = new { model.markOpened(p) }
                }
            }
        }
        .navigationTitle("Projects")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                addMenu
            }
        }
        .alert("Error", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK") { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "")
        }
    }

    private var addMenu: some View {
        Menu {
            Button("Open Existing Folder…") {
                Task { await model.addExistingFolder() }
            }
            Button("Create New Folder…") {
                Task { await model.createNewFolder() }
            }
        } label: {
            Label("Add Project", systemImage: "plus")
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}
