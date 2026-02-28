import SwiftUI

enum AppThemeOption: String, CaseIterable, Sendable {
    case system
    case light
    case dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light:  .light
        case .dark:   .dark
        }
    }

    var displayName: String {
        switch self {
        case .system: L("System")
        case .light:  L("Light")
        case .dark:   L("Dark")
        }
    }
}
