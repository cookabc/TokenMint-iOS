/// Abstraction for encrypted vault file I/O.
protocol VaultRepositoryProtocol: Actor {
    func load() async throws -> Vault
    func save(_ vault: Vault) async throws
}
