import Foundation
import os

extension Logger {
    static let app = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TokenMint", category: "app")
    static let vault = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "TokenMint", category: "vault"
    )
    static let keychain = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "TokenMint", category: "keychain"
    )
    static let biometric = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "TokenMint", category: "biometric"
    )
}
