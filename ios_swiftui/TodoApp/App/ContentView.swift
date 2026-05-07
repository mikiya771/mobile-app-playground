import SwiftUI

// Flutter の MaterialApp > Scaffold に相当する骨格 View
// 後の Step で TodoListView / LoginView に置き換わる
struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.tint)
                Text("TodoApp")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("SwiftUI + SwiftData")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("TodoApp")
        }
    }
}

#Preview {
    ContentView()
}
