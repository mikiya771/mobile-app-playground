import UIKit

// Native screen opened in response to Flutter's `openNativeScreen` MethodChannel call.
//
// Presentation strategy: modal (pageSheet).
// Rationale: The UITabBarController's tab navigation is flat — it doesn't own a
// UINavigationController for push. Presenting modally keeps the native navigation
// model clean and makes dismissal unambiguous (swipe down or explicit button).
// See README §"Flutter→Native push".
final class NativeDetailViewController: UIViewController {

    private let route: String
    private let args: [String: Any]

    init(route: String, args: [String: Any]) {
        self.route = route
        self.args = args
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Native Screen"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(close)
        )
        setupUI()
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    private func setupUI() {
        let titleLabel = UILabel()
        titleLabel.text = "Native Detail Screen"
        titleLabel.font = .preferredFont(forTextStyle: .title1)
        titleLabel.textAlignment = .center

        let routeLabel = UILabel()
        routeLabel.text = "Route: \(route)"
        routeLabel.textColor = .secondaryLabel
        routeLabel.textAlignment = .center

        let argsLabel = UILabel()
        argsLabel.text = "Args: \(args)"
        argsLabel.textColor = .secondaryLabel
        argsLabel.textAlignment = .center
        argsLabel.numberOfLines = 0

        let note = UILabel()
        note.text = "Opened via Flutter→Native MethodChannel.\nDismiss with the close button or swipe down."
        note.textColor = .tertiaryLabel
        note.textAlignment = .center
        note.numberOfLines = 0
        note.font = .preferredFont(forTextStyle: .footnote)

        let stack = UIStackView(arrangedSubviews: [titleLabel, routeLabel, argsLabel, note])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
    }
}
