import UIKit

class OverlayViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "オーバーレイ"
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close, target: self, action: #selector(closeTapped)
        )

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(systemName: "square.stack.fill"))
        icon.tintColor = .systemPurple
        icon.contentMode = .scaleAspectFit
        icon.heightAnchor.constraint(equalToConstant: 80).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = "オーバーレイ画面"
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.textAlignment = .center

        let descLabel = UILabel()
        descLabel.text = "Modal（pageSheet）表示のデモです。\n✕ボタンまたは下にスワイプして閉じます。"
        descLabel.font = .preferredFont(forTextStyle: .body)
        descLabel.textColor = .secondaryLabel
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0

        let closeButton = UIButton(type: .system, primaryAction: UIAction(title: "閉じる") { [weak self] _ in
            self?.dismiss(animated: true)
        })
        closeButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)

        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(descLabel)
        stack.addArrangedSubview(closeButton)
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
        ])
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}
