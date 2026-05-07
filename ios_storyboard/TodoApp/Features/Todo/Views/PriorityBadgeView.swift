import UIKit

// AutoLayout 実習 + 優先度バッジ（SwiftUI の PriorityBadge に相当）
final class PriorityBadgeView: UIView {
    private let label = UILabel()

    var priority: TodoPriority = .medium {
        didSet { update() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        layer.cornerRadius = 8
        clipsToBounds = true

        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
        ])
        update()
    }

    private func update() {
        label.text = priority.label
        switch priority {
        case .low:    backgroundColor = .systemGreen
        case .medium: backgroundColor = .systemOrange
        case .high:   backgroundColor = .systemRed
        }
    }
}
