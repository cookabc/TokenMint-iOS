import Foundation

/// AES-256-GCM encrypted vault file I/O.
actor VaultRepository: VaultRepositoryProtocol {
    private let keychain: KeychainServiceProtocol
    private let fileURL: URL

    init(keychain: KeychainServiceProtocol) {
        self.keychain = keychain
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let dir = appSupport.appendingPathComponent("TokenMint", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("vault.enc")
    }

    func load() async throws -> Vault {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return Vault()
        }
        // TODO: W8 — implement AES-256-GCM decryption
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(Vault.self, from: data)
    }

    func save(_ vault: Vault) async throws {
        // TODO: W8 — implement AES-256-GCM encryption
        let data = try JSONEncoder().encode(vault)
        try data.write(to: fileURL, options: .atomic)
    }
}
