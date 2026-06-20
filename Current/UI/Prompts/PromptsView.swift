import SwiftUI

struct PromptsView: View {
    var body: some View {
        ContentUnavailableView {
            Label("No Prompts", systemImage: "text.bubble")
        } description: {
            Text("Create reusable prompts for your agent workflows.")
        } actions: {
            Button("New Prompt") { }
                .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Prompts")
    }
}
