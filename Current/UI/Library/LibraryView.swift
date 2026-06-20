import SwiftUI

struct LibraryView: View {
    var body: some View {
        ContentUnavailableView {
            Label("No Documents", systemImage: "books.vertical")
        } description: {
            Text("Import documents to use as context in your agent runs.")
        } actions: {
            Button("Import Document") { }
                .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Library")
    }
}
