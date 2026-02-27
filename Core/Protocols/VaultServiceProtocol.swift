import Foundation

/// Abstraction for vault CRUD exposed to the UI layer.
@MainActor
protocol VaultServiceProtocol {
    var vault: Vault { get }
    func loadVault() async throws
    func addToken(_ token: Token) async throws
    func deleteToken(_ token: Token) async throws
    func updateToken(_ token: Token) async throws
    func reorderTokens(_ tokens: [Token]) async throws
}
