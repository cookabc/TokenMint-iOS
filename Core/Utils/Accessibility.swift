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
    static var addToken: String { L("Add New Token") }
    static var scanQR: String { L("Scan QR Code") }
    static var unlock: String { L("Tap to Unlock") }
    static var biometricToggle: String { L("Biometric Unlock") }
    static var hapticToggle: String { L("Haptic Feedback") }
    static var themeSelector: String { L("Theme") }
    static var exportVault: String { L("Export Vault") }
    static var importVault: String { L("Import Vault") }
    static var saveToken: String { L("Save Token") }
    static var addTokenManual: String { L("Add Manually") }
    static var scanAgain: String { L("Scan Again") }
    static var settings: String { L("Settings") }
    static var editList: String { L("Edit List") }
    static var deleteToken: String { L("Delete Token") }
    static func pinToken(_ isPinned: Bool) -> String {
        isPinned ? L("Unpin Token") : L("Pin Token")
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
    static var tokenRow: String { L("Double Tap to Copy Code") }
    static var addToken: String { L("Double Tap to Add a New Authenticator Token") }
    static var unlock: String { L("Double Tap to Authenticate") }
    static var saveToken: String { L("Double Tap to Save This Token") }
    static var exportVault: String { L("Double Tap to Export Vault as JSON") }
    static var importVault: String { L("Double Tap to Import Vault From File") }
    static var scanAgain: String { L("Double Tap to Scan Another QR Code") }
    static var settings: String { L("Double Tap to Open Settings") }
}
