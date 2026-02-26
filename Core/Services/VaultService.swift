import Foundation

/// Central vault management — @MainActor for SwiftUI observation.
@MainActor
@Observable
final class VaultService: VaultServiceProtocol {
    private(set) var vault: Vault = Vault()
    private let repository: VaultRepositoryProtocol
    private let keychain: KeychainServiceProtocol

    init(repository: VaultRepositoryProtocol, keychain: KeychainServiceProtocol) {
        self.repository = repository
        self.keychain = keychain
    }

    func loadVault() async throws {
        vault = try await repository.load()
    }

    func addToken(_ token: Token) async throws {
        var updated = vault
        var newToken = token
        newToken.sortOrder = updated.tokens.count
        updated.tokens.append(newToken)
        updated.vaultVersion += 1
        updated.updatedAt = Date()
        try await repository.save(updated)
        vault = updated
    }

    func deleteToken(_ token: Token) async throws {
        var updated = vault
        updated.tokens.removeAll { $0.id == token.id }
        updated.vaultVersion += 1
        updated.updatedAt = Date()
        try await repository.save(updated)
        vault = updated
    }

    func updateToken(_ token: Token) async throws {
        var updated = vault
        guard let index = updated.tokens.firstIndex(where: { $0.id == token.id }) else { return }
        updated.tokens[index] = token
        updated.vaultVersion += 1
        updated.updatedAt = Date()
        try await repository.save(updated)
        vault = updated
    }

    func reorderTokens(_ tokens: [Token]) async throws {
        var updated = vault
        updated.tokens = tokens.enumerated().map { index, token in
            var t = token
            t.sortOrder = index
            return t
        }
        updated.vaultVersion += 1
        updated.updatedAt = Date()
        try await repository.save(updated)
        vault = updated
    }
}
