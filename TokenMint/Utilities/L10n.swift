//
//  L10n.swift
//  TokenMint
//
//  Localization strings - supports Chinese and English with in-app language switching
//

import Foundation
import SwiftUI
import Observation

// MARK: - Language Mode
enum LanguageMode: String, CaseIterable {
    case system = "system"
    case english = "en"
    case chinese = "zh-Hans"
    
    var displayName: String {
        switch self {
        case .system: return L10n.languageSystem
        case .english: return "English"
        case .chinese: return "简体中文"
        }
    }
}

// MARK: - Language Manager
@MainActor
@Observable
class LanguageManager {
    static let shared = LanguageManager()
    
    var languageMode: LanguageMode = .system {
        didSet {
            UserDefaults.standard.set(languageMode.rawValue, forKey: "appLanguage")
        }
    }
    
    private init() {
        if let data = UserDefaults.standard.string(forKey: "appLanguage"),
           let mode = LanguageMode(rawValue: data) {
            self.languageMode = mode
        }
    }
    
    var currentLanguageCode: String {
        switch languageMode {
        case .system:
            let preferredLanguage = Locale.preferredLanguages.first ?? "en"
            if preferredLanguage.hasPrefix("zh") {
                return "zh-Hans"
            }
            return "en"
        case .english:
            return "en"
        case .chinese:
            return "zh-Hans"
        }
    }
    
    func localizedString(forKey key: String) -> String {
        let languageCode = currentLanguageCode
        
        // Try to get the localized string from the appropriate bundle
        if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            let value = bundle.localizedString(forKey: key, value: nil, table: "Localizable")
            if value != key {
                return value
            }
        }
        
        // Fallback to English
        return englishStrings[key] ?? key
    }
    
    // English fallback dictionary
    private let englishStrings: [String: String] = [
        "copy": "Copy",
        "copied": "Copied",
        "cancel": "Cancel",
        "save": "Save",
        "delete": "Delete",
        "confirm": "Confirm",
        "settings": "Settings",
        "search": "Search",
        "add": "Add",
        "no_accounts": "No accounts yet",
        "no_results": "No results found",
        "add_first_account": "Add your first 2FA account",
        "search_accounts": "Search accounts...",
        "add_account": "Add Account",
        "enter_manually": "Enter details manually",
        "confirm_add": "Confirm & Add",
        "secret_required": "Secret key is required",
        "duplicate_account": "Duplicate account",
        "service": "Service",
        "account": "Account",
        "algorithm": "Algorithm",
        "language": "Language",
        "language_system": "System",
        "about": "About",
        "version": "Version",
        "edit": "Edit",
        "digits": "Digits",
        "period": "Period",
        "service_placeholder": "e.g. Google, GitHub",
        "account_placeholder": "e.g. user@example.com",
        "invalid_format": "Invalid format"
    ]
}

/// Localization helper
enum L10n {
    private static var manager: LanguageManager { LanguageManager.shared }
    
    static var copy: String { manager.localizedString(forKey: "copy") }
    static var copied: String { manager.localizedString(forKey: "copied") }
    static var cancel: String { manager.localizedString(forKey: "cancel") }
    static var save: String { manager.localizedString(forKey: "save") }
    static var delete: String { manager.localizedString(forKey: "delete") }
    static var confirm: String { manager.localizedString(forKey: "confirm") }
    static var settings: String { manager.localizedString(forKey: "settings") }
    static var search: String { manager.localizedString(forKey: "search") }
    static var add: String { manager.localizedString(forKey: "add") }
    
    static var noAccounts: String { manager.localizedString(forKey: "no_accounts") }
    static var noResults: String { manager.localizedString(forKey: "no_results") }
    static var addFirstAccount: String { manager.localizedString(forKey: "add_first_account") }
    static var searchAccounts: String { manager.localizedString(forKey: "search_accounts") }
    
    static var addAccount: String { manager.localizedString(forKey: "add_account") }
    static var enterManually: String { manager.localizedString(forKey: "enter_manually") }
    static var confirmAdd: String { manager.localizedString(forKey: "confirm_add") }
    static var secretRequired: String { manager.localizedString(forKey: "secret_required") }
    static var duplicateAccount: String { manager.localizedString(forKey: "duplicate_account") }
    static var service: String { manager.localizedString(forKey: "service") }
    static var account: String { manager.localizedString(forKey: "account") }
    static var algorithm: String { manager.localizedString(forKey: "algorithm") }
    static var invalidFormat: String { manager.localizedString(forKey: "invalid_format") }
    
    static var language: String { manager.localizedString(forKey: "language") }
    static var languageSystem: String { manager.localizedString(forKey: "language_system") }
    static var about: String { manager.localizedString(forKey: "about") }
    static var version: String { manager.localizedString(forKey: "version") }
    
    static var edit: String { manager.localizedString(forKey: "edit") }
    static var digits: String { manager.localizedString(forKey: "digits") }
    static var period: String { manager.localizedString(forKey: "period") }
    static var servicePlaceholder: String { manager.localizedString(forKey: "service_placeholder") }
    static var accountPlaceholder: String { manager.localizedString(forKey: "account_placeholder") }
}
