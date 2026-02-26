import Foundation

// MARK: - Token

struct Token: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var issuer: String
    var account: String
    var label: String
    var secret: String          // Base32 encoded
    var digits: Int             // 6 or 8
    var period: Int             // 30 or 60
    var algorithm: TOTPAlgorithm
    var sortOrder: Int
    var isPinned: Bool
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        issuer: String,
        account: String = "",
        label: String = "",
        secret: String,
        digits: Int = 6,
        period: Int = 30,
        algorithm: TOTPAlgorithm = .sha1,
        sortOrder: Int = 0,
        isPinned: Bool = false,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.issuer = issuer
        self.account = account
        self.label = label
        self.secret = secret.uppercased().replacingOccurrences(of: " ", with: "")
        self.digits = digits
        self.period = period
        self.algorithm = algorithm
        self.sortOrder = sortOrder
        self.isPinned = isPinned
        self.updatedAt = updatedAt
    }
}

// MARK: - Vault

struct Vault: Codable, Sendable {
    var tokens: [Token] = []
    var vaultVersion: Int = 0
    var schemaVersion: Int = 1
    var updatedAt = Date()
}

// MARK: - EncryptedVault

struct EncryptedVault: Codable, Sendable {
    let ciphertext: Data
    let nonce: Data
    let tag: Data
    let schemaVersion: Int
}

// MARK: - TOTPAlgorithm

enum TOTPAlgorithm: String, Codable, CaseIterable, Sendable {
    case sha1
    case sha256
    case sha512
}
