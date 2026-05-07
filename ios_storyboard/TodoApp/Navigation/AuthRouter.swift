import UIKit

// go_router の redirect に相当するルート切り替えヘルパー
// SceneDelegate の showTodoList / showLogin を呼び出す
enum AuthRouter {
    static func showTodoList() {
        guard let sceneDelegate = UIApplication.shared.connectedScenes
            .first?.delegate as? SceneDelegate else { return }
        sceneDelegate.showTodoList()
    }

    static func showLogin() {
        guard let sceneDelegate = UIApplication.shared.connectedScenes
            .first?.delegate as? SceneDelegate else { return }
        sceneDelegate.showLogin()
    }
}
