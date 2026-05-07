import UIKit

// Step 8: Segue DI で Todo を受け取り詳細表示
// Step 11 で WKWebView を追加
class TodoDetailViewController: UIViewController {
    var todo: Todo?

    private let titleLabel = UILabel()
    private let descLabel = UILabel()
    private let badgeView = PriorityBadgeView()
    private let dateLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "詳細"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Web詳細", style: .plain, target: self, action: #selector(showWebDetail)
        )
        setupUI()
        configure()
    }

    private func setupUI() {
        [titleLabel, descLabel, badgeView, dateLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.numberOfLines = 0
        descLabel.font = .preferredFont(forTextStyle: .body)
        descLabel.numberOfLines = 0
        descLabel.textColor = .secondaryLabel
        dateLabel.font = .preferredFont(forTextStyle: .caption1)
        dateLabel.textColor = .tertiaryLabel

        NSLayoutConstraint.activate([
            badgeView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            badgeView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            titleLabel.topAnchor.constraint(equalTo: badgeView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            dateLabel.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 12),
            dateLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
        ])
    }

    @objc private func showWebDetail() {
        let vc = TodoWebViewController()
        vc.todo = todo
        navigationController?.pushViewController(vc, animated: true)
    }

    private func configure() {
        guard let todo else { return }
        badgeView.priority = todo.priority
        titleLabel.text = todo.title
        descLabel.text = todo.description.isEmpty ? "説明なし" : todo.description
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        dateLabel.text = formatter.string(from: todo.createdAt)
    }
}
