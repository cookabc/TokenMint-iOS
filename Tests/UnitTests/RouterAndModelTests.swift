import Foundation
import Testing
@testable import TokenMint

@Suite("Router Tests")
struct RouterTests {
    @MainActor
    @Test("Initial state has empty path")
    func initialState() {
        let router = Router()
        #expect(router.path.isEmpty)
    }

    @MainActor
    @Test("navigate appends to path")
    func navigate() {
        let router = Router()
        router.navigate(to: .addToken)
        #expect(!router.path.isEmpty)
    }

    @MainActor
    @Test("pop removes last")
    func pop() {
        let router = Router()
        router.navigate(to: .addToken)
        router.navigate(to: .settings)
        router.pop()
        #expect(!router.path.isEmpty)
    }

    @MainActor
    @Test("pop on empty is safe")
    func popEmpty() {
        let router = Router()
        router.pop()
        #expect(router.path.isEmpty)
    }

    @MainActor
    @Test("popToRoot clears all")
    func popToRoot() {
        let router = Router()
        router.navigate(to: .addToken)
        router.navigate(to: .scanner)
        router.navigate(to: .settings)
        router.popToRoot()
        #expect(router.path.isEmpty)
    }
}

@Suite("Token Model Tests")
struct TokenModelTests {
    @Test("Token initializes with defaults")
    func defaults() {
        let token = Token(issuer: "GitHub", secret: "ABC")
        #expect(token.issuer == "GitHub")
        #expect(token.digits == 6)
        #expect(token.period == 30)
        #expect(token.algorithm == .sha1)
        #expect(token.isPinned == false)
        #expect(token.sortOrder == 0)
    }

    @Test("Token cleans and uppercases secret")
    func secretCleaning() {
        let token = Token(issuer: "Test", secret: "jbsw y3dp")
        #expect(token.secret == "JBSWY3DP")
    }

    @Test("Token is Equatable")
    func equatable() {
        let id = UUID()
        let now = Date()
        let token1 = Token(id: id, issuer: "A", secret: "ABC", updatedAt: now)
        let token2 = Token(id: id, issuer: "A", secret: "ABC", updatedAt: now)
        #expect(token1 == token2)
    }

    @Test("Token JSON round-trip")
    func jsonRoundTrip() throws {
        let token = Token(
            issuer: "GitHub", account: "user@test.com", secret: "JBSWY3DPEHPK3PXP",
            digits: 8, period: 60, algorithm: .sha256, isPinned: true
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(token)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Token.self, from: data)

        #expect(decoded.issuer == token.issuer)
        #expect(decoded.account == token.account)
        #expect(decoded.digits == 8)
        #expect(decoded.period == 60)
        #expect(decoded.algorithm == .sha256)
        #expect(decoded.isPinned == true)
    }
}

@Suite("Vault Model Tests")
struct VaultModelTests {
    @Test("Empty vault has zero tokens")
    func emptyVault() {
        let vault = Vault()
        #expect(vault.tokens.isEmpty)
        #expect(vault.vaultVersion == 0)
        #expect(vault.schemaVersion == 1)
    }

    @Test("Vault JSON round-trip")
    func jsonRoundTrip() throws {
        var vault = Vault()
        vault.tokens = [Token(issuer: "Test", secret: "ABC")]
        vault.vaultVersion = 5

        let data = try JSONEncoder().encode(vault)
        let decoded = try JSONDecoder().decode(Vault.self, from: data)
        #expect(decoded.tokens.count == 1)
        #expect(decoded.vaultVersion == 5)
    }
}
