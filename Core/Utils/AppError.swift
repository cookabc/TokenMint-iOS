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
            String(localized: "Failed to load vault: \(msg)")
        case .vaultSaveFailed(let msg):
            String(localized: "Failed to save vault: \(msg)")
        case .encryptionFailed(let msg):
            String(localized: "Encryption failed: \(msg)")
        case .decryptionFailed(let msg):
            String(localized: "Decryption failed: \(msg)")
        case .keychainError(let status):
            String(localized: "Keychain error (code: \(status))")
        case .invalidBase32:
            String(localized: "Invalid Base32 secret key")
        case .invalidOTPAuthURL:
            String(localized: "Invalid otpauth:// URL format")
        case .biometricFailed(let msg):
            String(localized: "Biometric authentication failed: \(msg)")
        case .cameraDenied:
            String(localized: "Camera access denied. Please enable in Settings.")
        case .unknown(let msg):
            String(localized: "An unexpected error occurred: \(msg)")
        }
    }
}
