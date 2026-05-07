import UIKit

// Flutter の TodoCard ウィジェットに相当
final class TodoTableViewCell: UITableViewCell {
    private let checkButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let badgeView = PriorityBadgeView()
    private var onToggle: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        checkButton.translatesAutoresizingMaskIntoConstraints = false
        checkButton.addTarget(self, action: #selector(toggleTapped), for: .touchUpInside)
        checkButton.setContentHuggingPriority(.required, for: .horizontal)

        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        badgeView.translatesAutoresizingMaskIntoConstraints = false
        badgeView.setContentHuggingPriority(.required, for: .horizontal)

        contentView.addSubview(checkButton)
        contentView.addSubview(titleLabel)
        contentView.addSubview(badgeView)

        NSLayoutConstraint.activate([
            checkButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            checkButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkButton.widthAnchor.constraint(equalToConstant: 28),

            titleLabel.leadingAnchor.constraint(equalTo: checkButton.trailingAnchor, constant: 8),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            badgeView.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            badgeView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            badgeView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }

    func configure(with todo: Todo, onToggle: @escaping () -> Void) {
        self.onToggle = onToggle
        badgeView.priority = todo.priority

        let attrs: [NSAttributedString.Key: Any] = todo.isCompleted
            ? [.strikethroughStyle: NSUnderlineStyle.single.rawValue, .foregroundColor: UIColor.secondaryLabel]
            : [.foregroundColor: UIColor.label]
        titleLabel.attributedText = NSAttributedString(string: todo.title, attributes: attrs)

        let img = UIImage(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
        checkButton.setImage(img, for: .normal)
        checkButton.tintColor = todo.isCompleted ? .systemBlue : .secondaryLabel
    }

    @objc private func toggleTapped() { onToggle?() }
}
