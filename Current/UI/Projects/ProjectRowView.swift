import SwiftUI

struct ProjectRowView: View {
    @Environment(AppState.self) private var appState
    let project: ProjectRecord

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: project.gitEnabled ? "arrow.triangle.branch" : "folder")
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.body)
                Text(project.folderPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button("Remove from App", role: .destructive) {
                appState.projectListModel.delete(project)
            }
        }
    }
}
