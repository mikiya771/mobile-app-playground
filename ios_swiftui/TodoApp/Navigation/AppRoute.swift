import Foundation

// go_router の RouteBase enum に相当
enum AppRoute: Hashable {
    case todoDetail(id: String)
    case todoForm(todo: Todo?)

    func hash(into hasher: inout Hasher) {
        switch self {
        case .todoDetail(let id): hasher.combine(0); hasher.combine(id)
        case .todoForm(let todo): hasher.combine(1); hasher.combine(todo?.id)
        }
    }

    static func == (lhs: AppRoute, rhs: AppRoute) -> Bool {
        switch (lhs, rhs) {
        case (.todoDetail(let a), .todoDetail(let b)): a == b
        case (.todoForm(let a), .todoForm(let b)): a?.id == b?.id
        default: false
        }
    }
}
