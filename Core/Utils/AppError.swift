import Foundation

/// Unified error type for TokenMint.
enum AppError: LocalizedError, Sendable {
    case vaultLoadFailed(underlying: String)
    case vaultSaveFailed(underlying: String)
    case encryptionFailed(underlying: String)
    case decryptionFailed(underlying: String)
    case keychainError(status: OSStatus)
    case invalidBase32
    case invalidOTPAuthURL
    case biometricFailed(underlying: String)
    case cameraDenied
    case unknown(underlying: String)

    var errorDescription: String? {
        switch self {
        case .vaultLoadFailed(let msg):
            L("Failed to load vault: \(msg)")
        case .vaultSaveFailed(let msg):
            L("Failed to save vault: \(msg)")
        case .encryptionFailed(let msg):
            L("Encryption failed: \(msg)")
        case .decryptionFailed(let msg):
            L("Decryption failed: \(msg)")
        case .keychainError(let status):
            L("Keychain error (code: \(status))")
        case .invalidBase32:
            L("Invalid Base32 secret key")
        case .invalidOTPAuthURL:
            L("Invalid otpauth:// URL format")
        case .biometricFailed(let msg):
            L("Biometric authentication failed: \(msg)")
        case .cameraDenied:
            L("Camera access denied. Please enable in Settings.")
        case .unknown(let msg):
            L("An unexpected error occurred: \(msg)")
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .vaultLoadFailed, .vaultSaveFailed:
            L("Please restart the app. If the problem persists, reinstall.")
        case .encryptionFailed, .decryptionFailed:
            L("Re-authenticate and try again.")
        case .keychainError:
            L("Check device passcode settings and try again.")
        case .invalidBase32, .invalidOTPAuthURL:
            L("Verify the QR code or manual entry and try again.")
        case .biometricFailed:
            L("Try again, or use your device passcode.")
        case .cameraDenied:
            L("Open Settings > TokenMint > Camera to enable.")
        case .unknown:
            L("Please try again later.")
        }
    }
}
