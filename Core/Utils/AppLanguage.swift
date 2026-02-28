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
        case .system: L("System")
        case .en:     "English"
        case .zhHans: "简体中文"
        }
    }

    // MARK: - Effective Locale

    /// The effective locale based on the current in-app language setting.
    /// Reads directly from UserDefaults so non-View code can access it.
    static var effectiveLocale: Locale {
        let raw = UserDefaults.standard.string(forKey: "appLanguage") ?? "system"
        guard let lang = AppLanguage(rawValue: raw), let locale = lang.locale else {
            return .current
        }
        return locale
    }
}

// MARK: - Locale-Aware Localization Helper

/// Locale-aware replacement for `String(localized:)` that respects in-app language override.
func L(_ key: String.LocalizationValue) -> String {
    String(localized: key, locale: AppLanguage.effectiveLocale)
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
