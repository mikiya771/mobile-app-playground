import UIKit

final class ActivityViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        let label = UILabel()
        label.text = "Activity (Native)"
        label.font = .preferredFont(forTextStyle: .largeTitle)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        let sub = UILabel()
        sub.text = "Native UIKit tab. Flutter engine idle but alive."
        sub.textAlignment = .center
        sub.textColor = .secondaryLabel
        sub.font = .preferredFont(forTextStyle: .body)
        sub.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [label, sub])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
        ])
    }
}
