import SwiftUI

// Step 11: WKWebView で詳細ページを表示する
struct TodoDetailWebView: View {
    let todoId: String
    @State private var webViewKey = UUID()  // リロード用

    private var url: URL {
        URL(string: "https://jsonplaceholder.typicode.com/todos/\(todoId.replacingOccurrences(of: "api_", with: ""))")!
    }

    var body: some View {
        WebViewRepresentable(url: url, allowedHosts: WebViewConfig.allowedHosts)
            .id(webViewKey)
            .navigationTitle("詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        webViewKey = UUID()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
    }
}

#Preview {
    NavigationStack {
        TodoDetailWebView(todoId: "api_1")
    }
}
