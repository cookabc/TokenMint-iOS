//
//  VaultService.swift
//  TokenMint
//
//  Encrypted vault storage service
//

import Foundation
import CryptoKit
import Combine
import SwiftUI

/// Service for managing encrypted vault storage
final class VaultService: ObservableObject {
    static let shared = VaultService()
    
    @Published private(set) var vault: Vault = Vault()
    @Published private(set) var isUnlocked: Bool = false
    @Published private(set) var initializationError: Error?
    
    private var encryptionKey: SymmetricKey?
    private let keychain = KeychainService.shared
    
    private let vaultFileURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let tokenmintDir = appSupport.appendingPathComponent("TokenMint", isDirectory: true)
        try? FileManager.default.createDirectory(at: tokenmintDir, withIntermediateDirectories: true)
        return tokenmintDir.appendingPathComponent("vault.enc")
    }()
    
    private init() {
        // Auto-unlock on init
        initializeAndUnlock()
    }
    
    // MARK: - Auto Initialization
    
    /// Initialize encryption key and unlock vault automatically
    private func initializeAndUnlock() {
        do {
            encryptionKey = try getOrCreateEncryptionKey()
            try loadVault()
            isUnlocked = true
            initializationError = nil
        } catch {
            print("Failed to initialize vault: \(error)")
            initializationError = error
            isUnlocked = false
        }
    }
    
    /// Get existing key from Keychain or create a new one
    private func getOrCreateEncryptionKey() throws -> SymmetricKey {
        // Try to load existing key from Keychain
        switch keychain.load(key: KeychainService.Keys.encryptionKey) {
        case .success(let keyData):
            return SymmetricKey(data: keyData)

        case .failure(let error):
            // Only generate new key if item not found
            if case .itemNotFound = error {
                // Generate new random key
                let key = SymmetricKey(size: .bits256)
                let keyData = key.withUnsafeBytes { Data($0) }

                // Save to Keychain
                guard keychain.save(key: KeychainService.Keys.encryptionKey, data: keyData) else {
                    throw VaultError.keyDerivationFailed
                }

                return key
            } else {
                // Propagate other errors
                print("Keychain error: \(error)")
                throw VaultError.keyDerivationFailed
            }
        }
    }
    
    /// Lock the vault (for manual lock if needed)
    func lock() {
        isUnlocked = false
        vault = Vault()
    }
    
    /// Unlock vault (re-initialize)
    func unlock() {
        initializeAndUnlock()
    }
    
    // MARK: - Vault Operations
    
    /// Load vault from disk
    func loadVault() throws {
        guard let key = encryptionKey else {
            throw VaultError.locked
        }
        
        guard FileManager.default.fileExists(atPath: vaultFileURL.path) else {
            vault = Vault()
            return
        }
        
        let data = try Data(contentsOf: vaultFileURL)
        let encryptedVault = try JSONDecoder().decode(EncryptedVault.self, from: data)
        
        // Decrypt
        let nonce = try AES.GCM.Nonce(data: encryptedVault.nonce)
        let sealedBox = try AES.GCM.SealedBox(nonce: nonce, ciphertext: encryptedVault.ciphertext, tag: encryptedVault.tag)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        vault = try JSONDecoder().decode(Vault.self, from: decryptedData)
    }
    
    /// Save vault to disk
    func saveVault() throws {
        guard isUnlocked, let key = encryptionKey else {
            throw VaultError.locked
        }
        
        vault.incrementVersion()
        
        let plainData = try JSONEncoder().encode(vault)
        let nonce = AES.GCM.Nonce()
        let sealedBox = try AES.GCM.seal(plainData, using: key, nonce: nonce)
        
        let encryptedVault = EncryptedVault(
            version: EncryptedVault.currentVersion,
            salt: Data(),  // Not used for device-key encryption
            iterations: 0,
            nonce: Data(nonce),
            ciphertext: sealedBox.ciphertext,
            tag: sealedBox.tag
        )
        
        let data = try JSONEncoder().encode(encryptedVault)
        try data.write(to: vaultFileURL, options: .atomic)
    }
    
    // MARK: - Token Operations
    
    /// Check if a token with the same secret already exists
    func isDuplicate(secret: String) -> Bool {
        let normalizedSecret = secret.uppercased().replacingOccurrences(of: " ", with: "")
        return vault.tokens.contains { $0.secret == normalizedSecret }
    }
    
    /// Add a new token
    func addToken(_ token: Token) throws {
        // Check for duplicate
        if isDuplicate(secret: token.secret) {
            throw VaultError.duplicateToken
        }
        
        var newToken = token
        newToken.sortOrder = vault.tokens.count
        newToken.updatedAt = Date()
        vault.tokens.append(newToken)
        try saveVault()
    }
    
    /// Update an existing token
    func updateToken(_ token: Token) throws {
        guard let index = vault.tokens.firstIndex(where: { $0.id == token.id }) else {
            throw VaultError.tokenNotFound
        }
        
        var updatedToken = token
        updatedToken.updatedAt = Date()
        vault.tokens[index] = updatedToken
        try saveVault()
    }
    
    /// Delete a token
    func deleteToken(id: UUID) throws {
        vault.tokens.removeAll { $0.id == id }
        try saveVault()
    }
    
    /// Clear all tokens
    func clearAllTokens() throws {
        vault.tokens.removeAll()
        try saveVault()
    }
    
    /// Reorder tokens
    func reorderTokens(from source: IndexSet, to destination: Int) throws {
        vault.tokens.move(fromOffsets: source, toOffset: destination)
        for (index, _) in vault.tokens.enumerated() {
            vault.tokens[index].sortOrder = index
        }
        try saveVault()
    }
    
    // MARK: - Vault Version
    
    var currentVaultVersion: Int {
        vault.vaultVersion
    }
}

// MARK: - Errors

enum VaultError: LocalizedError {
    case locked
    case keyDerivationFailed
    case corruptedData
    case tokenNotFound
    case noVaultFile
    case duplicateToken
    
    var errorDescription: String? {
        switch self {
        case .locked:
            return "Vault is locked"
        case .keyDerivationFailed:
            return "Failed to create encryption key"
        case .corruptedData:
            return "Vault data is corrupted"
        case .tokenNotFound:
            return "Token not found"
        case .noVaultFile:
            return "Vault file not found"
        case .duplicateToken:
            return "Duplicate account"
        }
    }
}
