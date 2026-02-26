import Foundation

/// Abstraction for iOS Keychain operations.
protocol KeychainServiceProtocol: Actor {
    func saveKey(_ key: Data, for account: String) async throws
    func loadKey(for account: String) async throws -> Data?
    func deleteKey(for account: String) async throws
}
