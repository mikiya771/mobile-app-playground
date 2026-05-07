import UIKit

// Step 5 & 6: UITableView + swipe削除 + toggle
// Step 7 で ViewModel に接続（現在はサンプルデータ直接参照）
class TodoListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    private var todos = Todo.samples
    private var filter: TodoFilter = .all

    private var filteredTodos: [Todo] {
        switch filter {
        case .all: todos
        case .active: todos.filter { !$0.isCompleted }
        case .completed: todos.filter { $0.isCompleted }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Todo"
        setupTableView()
        setupFilterBar()
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TodoTableViewCell.self, forCellReuseIdentifier: "TodoCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
    }

    private func setupFilterBar() {
        let seg = UISegmentedControl(items: TodoFilter.allCases.map { $0.rawValue })
        seg.selectedSegmentIndex = 0
        seg.addTarget(self, action: #selector(filterChanged(_:)), for: .valueChanged)

        let bar = UIToolbar()
        bar.items = [UIBarButtonItem(customView: seg)]
        bar.sizeToFit()
        tableView.tableHeaderView = bar
    }

    @objc private func filterChanged(_ sender: UISegmentedControl) {
        filter = TodoFilter.allCases[sender.selectedSegmentIndex]
        tableView.reloadData()
    }

    @objc @IBAction func addTapped(_ sender: Any) {
        performSegue(withIdentifier: "showForm", sender: nil)
    }

    private func toggle(id: String) {
        guard let i = todos.firstIndex(where: { $0.id == id }) else { return }
        todos[i].isCompleted.toggle()
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource
extension TodoListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredTodos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoCell", for: indexPath) as! TodoTableViewCell
        let todo = filteredTodos[indexPath.row]
        cell.configure(with: todo) { [weak self] in self?.toggle(id: todo.id) }
        return cell
    }
}

// MARK: - UITableViewDelegate
extension TodoListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "showDetail", sender: filteredTodos[indexPath.row])
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let id = filteredTodos[indexPath.row].id
        let delete = UIContextualAction(style: .destructive, title: "削除") { [weak self] _, _, done in
            self?.todos.removeAll { $0.id == id }
            self?.tableView.deleteRows(at: [indexPath], with: .automatic)
            done(true)
        }
        delete.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
