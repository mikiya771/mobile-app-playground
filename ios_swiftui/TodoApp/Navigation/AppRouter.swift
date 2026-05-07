import SwiftUI

// go_router の GoRouter に相当
// @Observable で isLoggedIn を保持し AuthGuard を実現する
@Observable
@MainActor
final class AppRouter {
    var path = NavigationPath()
    var isLoggedIn = false

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        if !path.isEmpty { path.removeLast() }
    }

    func replaceRoot() {
        path = NavigationPath()
    }
}
