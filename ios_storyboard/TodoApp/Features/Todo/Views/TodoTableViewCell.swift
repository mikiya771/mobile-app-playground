import UIKit

// Step 5 で本実装
class TodoTableViewCell: UITableViewCell {
    func configure(with todo: Todo) {
        textLabel?.text = todo.title
    }
}
