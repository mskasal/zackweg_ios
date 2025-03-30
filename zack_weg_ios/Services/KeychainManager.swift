import Foundation
import Security

enum KeychainError: Error {
    case unhandledError(status: OSStatus)
    case itemNotFound
    case duplicateItem
    case invalidItemFormat
    case unexpectedStatus(OSStatus)
}

class KeychainManager {
    static let shared = KeychainManager()
    
    private init() {}
    
    // MARK: - Keychain Keys
    struct Keys {
        static let authToken = "authToken"
        static let userId = "userId"
        static let userEmail = "userEmail"
        static let postalCode = "postalCode"
        static let countryCode = "countryCode"
        static let nickName = "userNickName"
    }
    
    // MARK: - Save Methods
    
    /// Saves a string value to the keychain
    /// - Parameters:
    ///   - key: The key to store the value under
    ///   - value: The string value to store
    func save(key: String, value: String) throws {
        guard let valueData = value.data(using: .utf8) else {
            throw KeychainError.invalidItemFormat
        }
        
        // Create a query for the keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: valueData
        ]
        
        // Try to delete any existing item first (it's okay if it fails)
        SecItemDelete(query as CFDictionary)
        
        // Now add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    // MARK: - Retrieval Methods
    
    /// Retrieves a string value from the keychain
    /// - Parameter key: The key to retrieve
    /// - Returns: The stored string value
    func getString(key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
        
        guard let data = item as? Data, let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidItemFormat
        }
        
        return value
    }
    
    /// Checks if a key exists in the keychain
    /// - Parameter key: The key to check
    /// - Returns: true if the key exists
    func hasValue(for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Delete Methods
    
    /// Deletes a value from the keychain
    /// - Parameter key: The key to delete
    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    /// Deletes all stored values for this app from the keychain
    func clearAll() {
        let allKeys = [
            Keys.authToken,
            Keys.userId,
            Keys.userEmail,
            Keys.postalCode,
            Keys.countryCode,
            Keys.nickName
        ]
        
        for key in allKeys {
            try? delete(key: key)
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Saves the auth token to the keychain
    func saveAuthToken(_ token: String) {
        try? save(key: Keys.authToken, value: token)
    }
    
    /// Retrieves the auth token from the keychain
    func getAuthToken() -> String? {
        try? getString(key: Keys.authToken)
    }
    
    /// Saves the user ID to the keychain
    func saveUserId(_ userId: String) {
        try? save(key: Keys.userId, value: userId)
    }
    
    /// Retrieves the user ID from the keychain
    func getUserId() -> String? {
        try? getString(key: Keys.userId)
    }
    
    /// Saves the user email to the keychain
    func saveUserEmail(_ email: String) {
        try? save(key: Keys.userEmail, value: email)
    }
    
    /// Retrieves the user email from the keychain
    func getUserEmail() -> String? {
        try? getString(key: Keys.userEmail)
    }
    
    /// Saves the postal code to the keychain
    func savePostalCode(_ code: String) {
        try? save(key: Keys.postalCode, value: code)
    }
    
    /// Retrieves the postal code from the keychain
    func getPostalCode() -> String? {
        try? getString(key: Keys.postalCode)
    }
    
    /// Saves the country code to the keychain
    func saveCountryCode(_ code: String) {
        try? save(key: Keys.countryCode, value: code)
    }
    
    /// Retrieves the country code from the keychain
    func getCountryCode() -> String? {
        try? getString(key: Keys.countryCode)
    }
    
    /// Saves the user nickname to the keychain
    func saveNickName(_ name: String) {
        try? save(key: Keys.nickName, value: name)
    }
    
    /// Retrieves the user nickname from the keychain
    func getNickName() -> String? {
        try? getString(key: Keys.nickName)
    }
} 