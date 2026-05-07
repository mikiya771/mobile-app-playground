import UIKit
import WebKit

// Step 13: WKWebView + JS Bridge でトークンを受け取る
// SwiftUI 版の LoginWebView に相当
class LoginWebViewController: UIViewController {
    private var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ログイン (Web)"
        setupWebView()
        loadLoginPage()
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        let controller = WKUserContentController()
        // JS Bridge: window.webkit.messageHandlers.iOSAuth
        controller.add(WeakScriptHandler(self), name: "iOSAuth")
        config.userContentController = controller

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func loadLoginPage() {
        guard let url = Bundle.main.url(forResource: "login", withExtension: "html") else { return }
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }

    deinit {
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "iOSAuth")
    }
}

// MARK: - WKNavigationDelegate (ホワイトリスト)
extension LoginWebViewController: WKNavigationDelegate {
    private static let allowedHosts: Set<String> = ["localhost", "127.0.0.1"]

    func webView(
        _ webView: WKWebView,
        decidePolicyFor action: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let host = action.request.url?.host else { decisionHandler(.allow); return }
        decisionHandler(Self.allowedHosts.contains(host) ? .allow : .cancel)
    }
}

// MARK: - WKScriptMessageHandler (JS Bridge)
extension LoginWebViewController: WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == "iOSAuth",
              let body = message.body as? [String: Any],
              let token = body["token"] as? String else { return }

        Task { @MainActor in
            AuthViewModel.shared.login(token: token)
            dismiss(animated: true) { AuthRouter.showTodoList() }
        }
    }
}

// メモリリーク防止のためのラッパー
private class WeakScriptHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?
    init(_ delegate: WKScriptMessageHandler) { self.delegate = delegate }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}
