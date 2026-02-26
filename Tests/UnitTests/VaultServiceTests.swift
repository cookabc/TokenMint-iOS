import Foundation
import Testing
@testable import TokenMint

@Suite("VaultService Tests")
struct VaultServiceTests {
    // MARK: - Mock Repository

    actor MockVaultRepository: VaultRepositoryProtocol {
        var vault = Vault()
        var saveCallCount = 0
        var shouldThrow = false

        func load() async throws -> Vault {
            if shouldThrow { throw AppError.vaultLoadFailed(underlying: "mock") }
            return vault
        }

        func save(_ vault: Vault) async throws {
            if shouldThrow { throw AppError.vaultSaveFailed(underlying: "mock") }
            saveCallCount += 1
            self.vault = vault
        }
    }

    // MARK: - Mock Keychain

    actor MockKeychainService: KeychainServiceProtocol {
        var store: [String: Data] = [:]

        func saveKey(_ key: Data, for account: String) async throws {
            store[account] = key
        }

        func loadKey(for account: String) async throws -> Data? {
            store[account]
        }

        func deleteKey(for account: String) async throws {
            store.removeValue(forKey: account)
        }
    }

    // MARK: - Tests

    @MainActor
    @Test("loadVault populates vault")
    func loadVault() async throws {
        let repo = MockVaultRepository()
        let keychain = MockKeychainService()
        let service = VaultService(repository: repo, keychain: keychain)

        try await service.loadVault()
        #expect(service.vault.tokens.isEmpty)
    }

    @MainActor
    @Test("addToken persists and increments version")
    func addToken() async throws {
        let repo = MockVaultRepository()
        let keychain = MockKeychainService()
        let service = VaultService(repository: repo, keychain: keychain)

        let token = Token(issuer: "GitHub", secret: "JBSWY3DPEHPK3PXP")
        try await service.addToken(token)

        #expect(service.vault.tokens.count == 1)
        #expect(service.vault.tokens.first?.issuer == "GitHub")
        #expect(service.vault.vaultVersion == 1)
    }

    @MainActor
    @Test("deleteToken removes token")
    func deleteToken() async throws {
        let repo = MockVaultRepository()
        let keychain = MockKeychainService()
        let service = VaultService(repository: repo, keychain: keychain)

        let token = Token(issuer: "GitHub", secret: "JBSWY3DPEHPK3PXP")
        try await service.addToken(token)
        try await service.deleteToken(token)

        #expect(service.vault.tokens.isEmpty)
        #expect(service.vault.vaultVersion == 2)
    }

    @MainActor
    @Test("updateToken modifies existing token")
    func updateToken() async throws {
        let repo = MockVaultRepository()
        let keychain = MockKeychainService()
        let service = VaultService(repository: repo, keychain: keychain)

        let token = Token(issuer: "GitHub", secret: "JBSWY3DPEHPK3PXP")
        try await service.addToken(token)

        var updated = token
        updated.issuer = "GitLab"
        try await service.updateToken(updated)

        #expect(service.vault.tokens.first?.issuer == "GitLab")
    }

    @MainActor
    @Test("reorderTokens updates sort order")
    func reorderTokens() async throws {
        let repo = MockVaultRepository()
        let keychain = MockKeychainService()
        let service = VaultService(repository: repo, keychain: keychain)

        let token1 = Token(issuer: "A", secret: "JBSWY3DPEHPK3PXP")
        let token2 = Token(issuer: "B", secret: "JBSWY3DPEHPK3PXP")
        try await service.addToken(token1)
        try await service.addToken(token2)

        // Reverse order
        try await service.reorderTokens([token2, token1])

        #expect(service.vault.tokens[0].issuer == "B")
        #expect(service.vault.tokens[0].sortOrder == 0)
        #expect(service.vault.tokens[1].issuer == "A")
        #expect(service.vault.tokens[1].sortOrder == 1)
    }
}
