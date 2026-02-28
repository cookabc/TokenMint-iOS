import SwiftUI

/// In-app language override. Stored via @AppStorage("appLanguage").
enum AppLanguage: String, CaseIterable, Sendable {
    case system
    case en
    case zhHans = "zh-Hans"

    /// The locale to apply via `.environment(\.locale, ...)`.
    var locale: Locale? {
        switch self {
        case .system: nil
        case .en:     Locale(identifier: "en")
        case .zhHans: Locale(identifier: "zh-Hans")
        }
    }

    var displayName: String {
        switch self {
        case .system: String(localized: "System")
        case .en:     "English"
        case .zhHans: "简体中文"
        }
    }
}

// MARK: - View Extension

extension View {
    /// Apply locale override when user selected a specific language; passthrough for `.system`.
    @ViewBuilder
    func localeOverride(_ language: AppLanguage) -> some View {
        if let locale = language.locale {
            self.environment(\.locale, locale)
        } else {
            self
        }
    }
}
