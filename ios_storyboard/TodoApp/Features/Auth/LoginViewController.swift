import UIKit
import AuthenticationServices

// Step 2: IBAction + コードレイアウト（AutoLayout は Step 3 で整理）
// Step 13: WebView ログインを showWebLogin Segue に接続
// Step 15: OAuth を ASWebAuthenticationSession に置き換え
class LoginViewController: UIViewController {

    // Step 2: ボタンをコードで作成（Storyboard の空 View にのせる）
    private let titleLabel = UILabel()
    private let loginButton = UIButton(type: .system)
    private let oauthButton = UIButton(type: .system)
    private let stackView = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        titleLabel.text = "TodoApp"
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textAlignment = .center

        loginButton.setTitle("自社アカウントでログイン", for: .normal)
        loginButton.backgroundColor = .systemBlue
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.layer.cornerRadius = 10
        loginButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)

        oauthButton.setTitle("OAuthでログイン", for: .normal)
        oauthButton.layer.borderColor = UIColor.systemBlue.cgColor
        oauthButton.layer.borderWidth = 1
        oauthButton.layer.cornerRadius = 10
        oauthButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        oauthButton.addTarget(self, action: #selector(oauthTapped), for: .touchUpInside)

        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(loginButton)
        stackView.addArrangedSubview(oauthButton)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 32),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 32),
        ])
    }

    @objc @IBAction func loginTapped(_ sender: Any) {
        // Step 13: WebView ログイン画面をモーダル表示
        let webVC = LoginWebViewController()
        let nav = UINavigationController(rootViewController: webVC)
        webVC.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(dismissWebLogin)
        )
        present(nav, animated: true)
    }

    @objc private func dismissWebLogin() { dismiss(animated: true) }

    @objc @IBAction func oauthTapped(_ sender: Any) {
        // Step 15: ASWebAuthenticationSession で OAuth フロー
        startOAuthFlow()
    }
}

// MARK: - ASWebAuthenticationSession (Step 15)
extension LoginViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        view.window!
    }

    func startOAuthFlow() {
        // デモ用: 実際は認可サーバーの URL を指定
        guard let authURL = URL(string: "https://example.com/oauth/authorize?client_id=demo&redirect_uri=todoapp://callback&response_type=code") else { return }
        let session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "todoapp"
        ) { callbackURL, error in
            guard error == nil, let url = callbackURL,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let code = components.queryItems?.first(where: { $0.name == "code" })?.value
            else { return }

            Task { @MainActor in
                // 実際はコードをトークンエンドポイントで交換する
                AuthViewModel.shared.login(token: "oauth-\(code)")
                AuthRouter.showTodoList()
            }
        }
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = true
        session.start()
    }
}
