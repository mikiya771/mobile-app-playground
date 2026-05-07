import SwiftUI

// Step 8: 詳細画面のプレースホルダー
// Step 11 で WKWebView に置き換わる
struct TodoDetailWebView: View {
    let todoId: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("詳細 WebView")
                .font(.headline)
            Text("ID: \(todoId)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Step 11 で WKWebView を実装します")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .navigationTitle("詳細")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TodoDetailWebView(todoId: "api_1")
    }
}
