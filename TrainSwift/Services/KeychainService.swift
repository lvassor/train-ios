//
//  KeychainService.swift
//  TrainSwift
//
//  Secure password storage using iOS Keychain with SHA-256 hashing
//  Passwords are hashed before storage for additional security
//

import Foundation
import Security
import CryptoKit

enum KeychainError: Error {
    case duplicateEntry
    case unknown(OSStatus)
    case itemNotFound
    case invalidData
}

class KeychainService {
    static let shared = KeychainService()

    private let service = "com.trainapp.trainswift"

    // Salt for password hashing (in production, use unique salt per user stored separately)
    private let passwordSalt = "trAIn_secure_salt_2024"

    private init() {}

    // MARK: - Password Hashing

    /// Hash a password using SHA-256 with salt
    private func hashPassword(_ password: String) -> String {
        let saltedPassword = password + passwordSalt
        let inputData = Data(saltedPassword.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Save Password (Hashed)

    func savePassword(_ password: String, for email: String) throws {
        // Delete existing entry first
        try? deletePassword(for: email)

        // Hash the password before storing
        let hashedPassword = hashPassword(password)

        guard let passwordData = hashedPassword.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: email.lowercased(),
            kSecValueData as String: passwordData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }

        print("✅ Password hash saved to Keychain for: \(email)")
    }

    // MARK: - Retrieve Password Hash (Internal)

    private func retrievePasswordHash(for email: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: email.lowercased(),
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unknown(status)
        }

        guard let passwordData = result as? Data,
              let passwordHash = String(data: passwordData, encoding: .utf8) else {
            throw KeychainError.invalidData
        }

        return passwordHash
    }

    // MARK: - Delete Password

    func deletePassword(for email: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: email.lowercased()
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }

        print("✅ Password deleted from Keychain for: \(email)")
    }

    // MARK: - Update Password

    func updatePassword(_ newPassword: String, for email: String) throws {
        // Hash the new password
        let hashedPassword = hashPassword(newPassword)

        guard let passwordData = hashedPassword.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: email.lowercased()
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: passwordData
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        guard status == errSecSuccess else {
            // If item doesn't exist, create it
            if status == errSecItemNotFound {
                try savePassword(newPassword, for: email)
                return
            }
            throw KeychainError.unknown(status)
        }

        print("✅ Password hash updated in Keychain for: \(email)")
    }

    // MARK: - Verify Password

    func verifyPassword(_ password: String, for email: String) -> Bool {
        do {
            let storedHash = try retrievePasswordHash(for: email)
            let inputHash = hashPassword(password)
            return storedHash == inputHash
        } catch {
            print("❌ Keychain verification failed: \(error)")
            return false
        }
    }

    // MARK: - Apple Sign In Token Storage

    /// Save Apple Sign In user identifier
    func saveAppleUserIdentifier(_ identifier: String, for email: String) throws {
        try? deleteAppleUserIdentifier(for: email)

        guard let identifierData = identifier.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service + ".apple",
            kSecAttrAccount as String: email.lowercased(),
            kSecValueData as String: identifierData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }

        print("✅ Apple user identifier saved to Keychain")
    }

    /// Retrieve Apple Sign In user identifier
    func retrieveAppleUserIdentifier(for email: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service + ".apple",
            kSecAttrAccount as String: email.lowercased(),
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unknown(status)
        }

        guard let identifierData = result as? Data,
              let identifier = String(data: identifierData, encoding: .utf8) else {
            throw KeychainError.invalidData
        }

        return identifier
    }

    /// Delete Apple Sign In user identifier
    func deleteAppleUserIdentifier(for email: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service + ".apple",
            kSecAttrAccount as String: email.lowercased()
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }

    // MARK: - Google Sign In Token Storage

    /// Save Google Sign In user identifier
    func saveGoogleUserIdentifier(_ identifier: String, for email: String) throws {
        try? deleteGoogleUserIdentifier(for: email)

        guard let identifierData = identifier.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service + ".google",
            kSecAttrAccount as String: email.lowercased(),
            kSecValueData as String: identifierData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }

        print("✅ Google user identifier saved to Keychain")
    }

    /// Retrieve Google Sign In user identifier
    func retrieveGoogleUserIdentifier(for email: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service + ".google",
            kSecAttrAccount as String: email.lowercased(),
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unknown(status)
        }

        guard let identifierData = result as? Data,
              let identifier = String(data: identifierData, encoding: .utf8) else {
            throw KeychainError.invalidData
        }

        return identifier
    }

    /// Delete Google Sign In user identifier
    func deleteGoogleUserIdentifier(for email: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service + ".google",
            kSecAttrAccount as String: email.lowercased()
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }
}
