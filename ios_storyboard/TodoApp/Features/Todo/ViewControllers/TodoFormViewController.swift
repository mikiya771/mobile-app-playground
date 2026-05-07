import UIKit

// Step 1: プレースホルダー
// Step 7 で onSave クロージャを追加
class TodoFormViewController: UIViewController {
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var descField: UITextView!
    @IBOutlet weak var prioritySegment: UISegmentedControl!

    var editingTodo: Todo? = nil
    var onSave: ((Todo) -> Void)? = nil

    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
}
