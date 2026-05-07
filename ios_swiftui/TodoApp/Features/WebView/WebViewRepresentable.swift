import SwiftUI
import WebKit

// Flutter の webview_flutter に相当
// SwiftUI には WKWebView がないため UIViewRepresentable でラップする
struct WebViewRepresentable: UIViewRepresentable {
    let url: URL
    var onMessage: ((String) -> Void)? = nil    // Step 13 JS Bridge コールバック
    var allowedHosts: Set<String> = []           // Step 12 ホワイトリスト

    func makeCoordinator() -> Coordinator {
        Coordinator(onMessage: onMessage, allowedHosts: allowedHosts)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // Step 13: JS Bridge チャネル登録
        config.userContentController.add(context.coordinator, name: "FlutterAuth")
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        if webView.url != url {
            webView.load(request)
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let onMessage: ((String) -> Void)?
        let allowedHosts: Set<String>

        init(onMessage: ((String) -> Void)?, allowedHosts: Set<String>) {
            self.onMessage = onMessage
            self.allowedHosts = allowedHosts
        }

        // Step 12: ホワイトリスト制御
        func webView(_ webView: WKWebView,
                     decidePolicyFor action: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard !allowedHosts.isEmpty else {
                decisionHandler(.allow)
                return
            }
            let host = action.request.url?.host ?? ""
            if allowedHosts.contains(host) {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
                // アラートは Step 12 で外部に通知する仕組みを追加
            }
        }

        // Step 13: JS Bridge 受信
        func userContentController(_ controller: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            guard message.name == "FlutterAuth",
                  let body = message.body as? String else { return }
            onMessage?(body)
        }
    }
}
