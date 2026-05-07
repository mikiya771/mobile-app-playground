import UIKit

// Step 1: Storyboard ID "LoginVC"
// Step 2 で IBOutlet / IBAction を追加
// Step 13 で WebView ログインに置き換え
// Step 15 で OAuth を追加
class LoginViewController: UIViewController {

    @IBAction func loginTapped(_ sender: UIButton) {
        // Step 13 で WebView 遷移に置き換え
        AuthRouter.showTodoList()
    }

    @IBAction func oauthTapped(_ sender: UIButton) {
        // Step 15 で ASWebAuthenticationSession に置き換え
        AuthRouter.showTodoList()
    }
}
