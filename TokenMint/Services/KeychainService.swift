//
//  KeychainService.swift
//  TokenMint
//
//  Secure storage using iOS Keychain
//

import Foundation
import Security

/// Service for secure Keychain storage
final class KeychainService {
    static let shared = KeychainService()
    
    enum KeychainError: Error {
        case itemNotFound
        case duplicateItem
        case unexpectedStatus(OSStatus)
        case dataConversionError
    }

    private let serviceName = "com.tokenmint.app"
    
    private init() {}
    
    // MARK: - Generic Keychain Operations
    
    /// Save data to Keychain
    func save(key: String, data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        // Try to update first
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if status == errSecItemNotFound {
            // Item doesn't exist, add it
            var newQuery = query
            newQuery[kSecValueData as String] = data
            newQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked

            let addStatus = SecItemAdd(newQuery as CFDictionary, nil)
            return addStatus == errSecSuccess
        }

        return status == errSecSuccess
    }
    
    /// Load data from Keychain
    func load(key: String) -> Result<Data, KeychainError> {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            if let data = result as? Data {
                return .success(data)
            } else {
                return .failure(.dataConversionError)
            }
        } else if status == errSecItemNotFound {
            return .failure(.itemNotFound)
        } else {
            return .failure(.unexpectedStatus(status))
        }
    }
    
    /// Delete item from Keychain
    @discardableResult
    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Convenience Methods
    
    /// Save string to Keychain
    func saveString(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        return save(key: key, data: data)
    }
    
    /// Load string from Keychain
    func loadString(key: String) -> String? {
        switch load(key: key) {
        case .success(let data):
            return String(data: data, encoding: .utf8)
        case .failure:
            return nil
        }
    }
    
    // MARK: - Specific Keys
    
    enum Keys {
        static let encryptionKey = "encryption_key"
    }
}
