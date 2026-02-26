import SwiftUI

enum AppDestination: Hashable, Sendable {
    case addToken
    case scanner
    case settings
}

@MainActor
@Observable
final class Router {
    var path = NavigationPath()

    func navigate(to destination: AppDestination) {
        path.append(destination)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
