import UIKit

// Step 1: プレースホルダー
// Step 5 で UITableView を追加
// Step 7 で ViewModel に接続
class TodoListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    @IBAction func addTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showForm", sender: nil)
    }
}
