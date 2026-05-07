import UIKit

// Step 7: onSave クロージャで ViewModel に通知
class TodoFormViewController: UIViewController {
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var descField: UITextView!
    @IBOutlet weak var prioritySegment: UISegmentedControl!

    var editingTodo: Todo? = nil
    var onSave: ((Todo) -> Void)? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        title = editingTodo == nil ? "新規追加" : "編集"
        setupPrioritySegment()
        if let todo = editingTodo {
            titleField.text = todo.title
            descField.text = todo.description
            prioritySegment.selectedSegmentIndex = TodoPriority.allCases.firstIndex(of: todo.priority) ?? 1
        }
    }

    private func setupPrioritySegment() {
        prioritySegment.removeAllSegments()
        TodoPriority.allCases.enumerated().forEach { i, p in
            prioritySegment.insertSegment(withTitle: p.rawValue, at: i, animated: false)
        }
        prioritySegment.selectedSegmentIndex = 1
    }

    @IBAction func cancelTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    @IBAction func saveTapped(_ sender: UIBarButtonItem) {
        guard let title = titleField.text, !title.isEmpty else { return }
        let priority = TodoPriority.allCases[prioritySegment.selectedSegmentIndex]
        let todo = Todo(
            id: editingTodo?.id ?? UUID().uuidString,
            title: title,
            description: descField.text ?? "",
            isCompleted: editingTodo?.isCompleted ?? false,
            priority: priority,
            createdAt: editingTodo?.createdAt ?? .now
        )
        onSave?(todo)
        dismiss(animated: true)
    }
}
