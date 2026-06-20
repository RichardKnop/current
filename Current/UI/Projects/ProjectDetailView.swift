import SwiftUI

struct ProjectDetailView: View {
    let project: ProjectRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: project.gitEnabled ? "arrow.triangle.branch" : "folder")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(project.folderPath)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            LabeledContent("Git repository", value: project.gitEnabled ? "Yes" : "No")
            LabeledContent("Added", value: project.createdAt)
            if let opened = project.lastOpenedAt {
                LabeledContent("Last opened", value: opened)
            }

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle(project.name)
    }
}
