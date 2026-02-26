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
}

/// Accessibility labels for VoiceOver.
enum AccessibilityLabel {
    static let addToken = String(localized: "Add new token", comment: "Accessibility label")
    static let scanQR = String(localized: "Scan QR code", comment: "Accessibility label")
    static func totpCode(_ code: String) -> String {
        // Read digits individually for VoiceOver
        code.map(String.init).joined(separator: ", ")
    }
    static func copyToken(_ issuer: String) -> String {
        String(localized: "Copy code for \(issuer)", comment: "Accessibility label")
    }
    static let unlock = String(localized: "Tap to unlock", comment: "Accessibility label")
}

/// Accessibility hints for VoiceOver.
enum AccessibilityHint {
    static let tokenRow = String(
        localized: "Double tap to copy code", comment: "Accessibility hint"
    )
    static let addToken = String(
        localized: "Double tap to add a new authenticator token", comment: "Accessibility hint"
    )
}
