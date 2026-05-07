import UIKit
import WebKit

// Step 11: WKWebView で Todo 詳細を HTML レンダリング
// Flutter の TodoDetailWebView に相当
class TodoWebViewController: UIViewController {
    var todo: Todo?

    private var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Web詳細"
        setupWebView()
        loadHTML()
    }

    private func setupWebView() {
        webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func loadHTML() {
        guard let todo else { return }
        let priorityColor = switch todo.priority {
        case .low: "#28a745"
        case .medium: "#fd7e14"
        case .high: "#dc3545"
        }
        let status = todo.isCompleted ? "✅ 完了" : "⬜ 未完了"
        let html = """
        <!DOCTYPE html><html><head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
          body { font-family: -apple-system; margin: 16px; }
          .badge { display: inline-block; padding: 4px 12px; border-radius: 12px;
                   background: \(priorityColor); color: white; font-size: 14px; }
          h1 { font-size: 22px; }
          p { color: #666; }
        </style></head><body>
        <span class="badge">\(todo.priority.rawValue)</span>
        <h1>\(todo.title)</h1>
        <p>\(todo.description.isEmpty ? "説明なし" : todo.description)</p>
        <p>\(status)</p>
        </body></html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}
