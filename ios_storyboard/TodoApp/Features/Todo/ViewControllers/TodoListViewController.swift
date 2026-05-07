import UIKit

// Step 7: ViewModel + CoreData 連携
class TodoListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    private let viewModel = TodoListViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Todo"
        setupTableView()
        setupFilterBar()
        viewModel.onUpdate = { [weak self] in
            DispatchQueue.main.async { self?.tableView.reloadData() }
        }
        viewModel.loadTodos()
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
        viewModel.filter = TodoFilter.allCases[sender.selectedSegmentIndex]
    }

    @objc @IBAction func addTapped(_ sender: Any) {
        performSegue(withIdentifier: "showForm", sender: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail",
           let vc = segue.destination as? TodoDetailViewController {
            vc.todo = sender as? Todo
        }
        if segue.identifier == "showForm",
           let nav = segue.destination as? UINavigationController,
           let vc = nav.topViewController as? TodoFormViewController {
            vc.editingTodo = sender as? Todo
            vc.onSave = { [weak self] todo in self?.viewModel.save(todo) }
        }
    }
}

// MARK: - UITableViewDataSource
extension TodoListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.filteredTodos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoCell", for: indexPath) as! TodoTableViewCell
        let todo = viewModel.filteredTodos[indexPath.row]
        cell.configure(with: todo) { [weak self] in self?.viewModel.toggle(id: todo.id) }
        return cell
    }
}

// MARK: - UITableViewDelegate
extension TodoListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "showDetail", sender: viewModel.filteredTodos[indexPath.row])
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let id = viewModel.filteredTodos[indexPath.row].id
        let delete = UIContextualAction(style: .destructive, title: "削除") { [weak self] _, _, done in
            self?.viewModel.delete(id: id)
            done(true)
        }
        delete.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
