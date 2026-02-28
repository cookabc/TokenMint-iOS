import Foundation

/// Accessibility identifiers for UI testing.
enum AccessibilityID {
    // Token List
    static let tokenList = "token_list"
    static let addTokenButton = "add_token_button"
    static let scanQRButton = "scan_qr_button"
    static let tokenRow = "token_row"

    // Token Row
    static let copyButton = "copy_button"
    static let countdownRing = "countdown_ring"
    static let totpCode = "totp_code"

    // Add Token
    static let issuerField = "issuer_field"
    static let accountField = "account_field"
    static let secretField = "secret_field"
    static let saveTokenButton = "save_token_button"

    // Lock Screen
    static let unlockButton = "unlock_button"

    // Settings
    static let biometricToggle = "biometric_toggle"
    static let hapticToggle = "haptic_toggle"
    static let settingsThemePicker = "settings_theme_picker"
    static let settingsExportButton = "settings_export_button"
    static let settingsImportButton = "settings_import_button"
    static let settingsButton = "settings_button"
    static let editButton = "edit_button"
}

/// Accessibility labels for VoiceOver.
enum AccessibilityLabel {
    static var addToken: String { L("Add new token") }
    static var scanQR: String { L("Scan QR code") }
    static var unlock: String { L("Tap to unlock") }
    static var biometricToggle: String { L("Biometric unlock") }
    static var hapticToggle: String { L("Haptic feedback") }
    static var themeSelector: String { L("Theme") }
    static var exportVault: String { L("Export vault") }
    static var importVault: String { L("Import vault") }
    static var saveToken: String { L("Save token") }
    static var addTokenManual: String { L("Add manually") }
    static var scanAgain: String { L("Scan again") }
    static var settings: String { L("Settings") }
    static var editList: String { L("Edit list") }
    static var deleteToken: String { L("Delete token") }
    static func pinToken(_ isPinned: Bool) -> String {
        isPinned ? L("Unpin token") : L("Pin token")
    }
    static func totpCode(_ code: String) -> String {
        code.map(String.init).joined(separator: ", ")
    }
    static func copyToken(_ issuer: String) -> String {
        L("Copy code for \(issuer)")
    }
}

/// Accessibility hints for VoiceOver.
enum AccessibilityHint {
    static var tokenRow: String { L("Double tap to copy code") }
    static var addToken: String { L("Double tap to add a new authenticator token") }
    static var unlock: String { L("Double tap to authenticate") }
    static var saveToken: String { L("Double tap to save this token") }
    static var exportVault: String { L("Double tap to export vault as JSON") }
    static var importVault: String { L("Double tap to import vault from file") }
    static var scanAgain: String { L("Double tap to scan another QR code") }
    static var settings: String { L("Double tap to open settings") }
}
