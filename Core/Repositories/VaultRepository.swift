import CryptoKit
import Foundation

/// AES-256-GCM encrypted vault persistence backed by Keychain key storage.
actor VaultRepository: VaultRepositoryProtocol {
    private let keychain: KeychainServiceProtocol
    private let fileURL: URL
    private static let keychainAccount = "vault_encryption_key"

    init(keychain: KeychainServiceProtocol) {
        self.keychain = keychain
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first
        guard let appSupport else {
            fatalError("Application Support directory not found")
        }
        let dir = appSupport.appendingPathComponent("TokenMint", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("vault.enc")
    }

    func load() async throws -> Vault {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return Vault()
        }
        let encryptedData = try Data(contentsOf: fileURL)
        let encryptedVault = try JSONDecoder().decode(EncryptedVault.self, from: encryptedData)
        let key = try await getOrCreateKey()
        let sealedBox = try AES.GCM.SealedBox(
            nonce: AES.GCM.Nonce(data: encryptedVault.nonce),
            ciphertext: encryptedVault.ciphertext,
            tag: encryptedVault.tag
        )
        let plaintext = try AES.GCM.open(sealedBox, using: key)
        return try JSONDecoder().decode(Vault.self, from: plaintext)
    }

    func save(_ vault: Vault) async throws {
        let key = try await getOrCreateKey()
        let plaintext = try JSONEncoder().encode(vault)
        let sealedBox = try AES.GCM.seal(plaintext, using: key)
        let encryptedVault = EncryptedVault(
            ciphertext: sealedBox.ciphertext,
            nonce: Data(sealedBox.nonce),
            tag: sealedBox.tag,
            schemaVersion: vault.schemaVersion
        )
        let data = try JSONEncoder().encode(encryptedVault)
        try data.write(to: fileURL, options: .atomic)
    }

    // MARK: - Key Management

    private func getOrCreateKey() async throws -> SymmetricKey {
        if let existingData = try await keychain.loadKey(for: Self.keychainAccount) {
            return SymmetricKey(data: existingData)
        }
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        try await keychain.saveKey(keyData, for: Self.keychainAccount)
        return newKey
    }
}
