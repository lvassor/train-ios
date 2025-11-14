//
//  KeychainService.swift
//  trAInSwift
//
//  Secure password storage using iOS Keychain
//  Works in simulator and on device
//

import Foundation
import Security

enum KeychainError: Error {
    case duplicateEntry
    case unknown(OSStatus)
    case itemNotFound
    case invalidData
}

class KeychainService {
    static let shared = KeychainService()

    private let service = "com.trainapp.trainswift"

    private init() {}

    // MARK: - Save Password

    func savePassword(_ password: String, for email: String) throws {
        // Delete existing entry first
        try? deletePassword(for: email)

        guard let passwordData = password.data(using: .utf8) else {
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

        print("✅ Password saved to Keychain for: \(email)")
    }

    // MARK: - Retrieve Password

    func retrievePassword(for email: String) throws -> String {
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
              let password = String(data: passwordData, encoding: .utf8) else {
            throw KeychainError.invalidData
        }

        return password
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
        guard let passwordData = newPassword.data(using: .utf8) else {
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

        print("✅ Password updated in Keychain for: \(email)")
    }

    // MARK: - Verify Password

    func verifyPassword(_ password: String, for email: String) -> Bool {
        do {
            let storedPassword = try retrievePassword(for: email)
            return storedPassword == password
        } catch {
            print("❌ Keychain verification failed: \(error)")
            return false
        }
    }
}
