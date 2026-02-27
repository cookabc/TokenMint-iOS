import Foundation
import os

extension Logger {
    /// Shared subsystem identifier.
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.example.TokenMint"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let vault = Logger(subsystem: subsystem, category: "vault")
    static let keychain = Logger(subsystem: subsystem, category: "keychain")
    static let biometric = Logger(subsystem: subsystem, category: "biometric")
    static let network = Logger(subsystem: subsystem, category: "network")
    static let services = Logger(subsystem: subsystem, category: "services")
}
