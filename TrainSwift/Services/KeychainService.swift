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
import CommonCrypto

enum KeychainError: Error {
    case duplicateEntry
    case unknown(OSStatus)
    case itemNotFound
    case invalidData
}

class KeychainService {
    static let shared = KeychainService()

    private let service = "com.trainapp.trainswift"
    private let saltService: String

    // PBKDF2 parameters (OWASP recommended)
    private let pbkdf2Iterations: Int = 600_000
    private let pbkdf2KeyLength: Int = 32  // 256-bit derived key

    // Legacy salt for backward-compatible verification during migration
    private let legacySalt = "trAIn_secure_salt_2024"

    private init() {
        self.saltService = service + ".salt"
    }

    // MARK: - Salt Generation

    /// Generate a cryptographically random 16-byte salt
    private func generateSalt() -> Data {
        var salt = Data(count: 16)
        salt.withUnsafeMutableBytes { buffer in
            _ = SecRandomCopyBytes(kSecRandomDefault, 16, buffer.baseAddress!)
        }
        return salt
    }

    /// Save per-user salt to Keychain
    private func saveSalt(_ salt: Data, for email: String) throws {
        try? deleteSalt(for: email)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: saltService,
            kSecAttrAccount as String: email.lowercased(),
            kSecValueData as String: salt,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }

    /// Retrieve per-user salt from Keychain
    private func retrieveSalt(for email: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: saltService,
            kSecAttrAccount as String: email.lowercased(),
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let saltData = result as? Data else {
            throw KeychainError.itemNotFound
        }

        return saltData
    }

    /// Delete per-user salt from Keychain
    private func deleteSalt(for email: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: saltService,
            kSecAttrAccount as String: email.lowercased()
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Password Hashing (PBKDF2-SHA256)

    /// Derive a key from password + salt using PBKDF2-SHA256
    private func deriveKey(password: String, salt: Data) -> String {
        let passwordData = Data(password.utf8)
        var derivedKey = Data(count: pbkdf2KeyLength)

        let result = derivedKey.withUnsafeMutableBytes { derivedKeyBuffer in
            salt.withUnsafeBytes { saltBuffer in
                passwordData.withUnsafeBytes { passwordBuffer in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBuffer.baseAddress?.assumingMemoryBound(to: Int8.self),
                        passwordData.count,
                        saltBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(pbkdf2Iterations),
                        derivedKeyBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        pbkdf2KeyLength
                    )
                }
            }
        }

        guard result == kCCSuccess else {
            // Fallback to SHA-256 if PBKDF2 fails (should never happen)
            AppLogger.logAuth("PBKDF2 derivation failed, falling back to SHA-256", level: .error)
            return legacyHashPassword(password)
        }

        return derivedKey.map { String(format: "%02x", $0) }.joined()
    }

    /// Legacy SHA-256 hash for backward compatibility during migration
    private func legacyHashPassword(_ password: String) -> String {
        let saltedPassword = password + legacySalt
        let inputData = Data(saltedPassword.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Save Password (PBKDF2 Hashed with Per-User Salt)

    func savePassword(_ password: String, for email: String) throws {
        // Delete existing entry first
        try? deletePassword(for: email)

        // Generate unique salt for this user
        let salt = generateSalt()
        try saveSalt(salt, for: email)

        // Derive key using PBKDF2
        let derivedKey = deriveKey(password: password, salt: salt)

        guard let keyData = derivedKey.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: email.lowercased(),
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }

        AppLogger.logAuth("Password (PBKDF2) saved to Keychain for: \(email)")
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

        AppLogger.logAuth("Password deleted from Keychain for: \(email)")
    }

    // MARK: - Update Password

    func updatePassword(_ newPassword: String, for email: String) throws {
        // Re-save with new PBKDF2 hash (generates new salt)
        try savePassword(newPassword, for: email)
        AppLogger.logAuth("Password (PBKDF2) updated in Keychain for: \(email)")
    }

    // MARK: - Verify Password (with automatic legacy migration)

    func verifyPassword(_ password: String, for email: String) -> Bool {
        do {
            let storedHash = try retrievePasswordHash(for: email)

            // Try PBKDF2 verification first (new format)
            if let salt = try? retrieveSalt(for: email) {
                let inputHash = deriveKey(password: password, salt: salt)
                if storedHash == inputHash {
                    return true
                }
            }

            // Fall back to legacy SHA-256 verification (for pre-migration accounts)
            let legacyHash = legacyHashPassword(password)
            if storedHash == legacyHash {
                // Transparently migrate to PBKDF2 on successful legacy verification
                AppLogger.logAuth("Migrating password from SHA-256 to PBKDF2 for: \(email)")
                try? savePassword(password, for: email)
                return true
            }

            return false
        } catch {
            AppLogger.logAuth("Keychain verification failed: \(error)", level: .error)
            return false
        }
    }

    // MARK: - Generic Identifier Storage (shared by Apple/Google)

    private func saveIdentifier(_ identifier: String, for email: String, serviceSuffix: String) throws {
        try? deleteIdentifier(for: email, serviceSuffix: serviceSuffix)

        guard let identifierData = identifier.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service + ".\(serviceSuffix)",
            kSecAttrAccount as String: email.lowercased(),
            kSecValueData as String: identifierData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }

    private func retrieveIdentifier(for email: String, serviceSuffix: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service + ".\(serviceSuffix)",
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

    private func deleteIdentifier(for email: String, serviceSuffix: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service + ".\(serviceSuffix)",
            kSecAttrAccount as String: email.lowercased()
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }

    // MARK: - Apple Sign In Token Storage

    func saveAppleUserIdentifier(_ identifier: String, for email: String) throws {
        try saveIdentifier(identifier, for: email, serviceSuffix: "apple")
        AppLogger.logAuth("Apple user identifier saved to Keychain")
    }

    func retrieveAppleUserIdentifier(for email: String) throws -> String {
        try retrieveIdentifier(for: email, serviceSuffix: "apple")
    }

    func deleteAppleUserIdentifier(for email: String) throws {
        try deleteIdentifier(for: email, serviceSuffix: "apple")
    }

    // MARK: - Google Sign In Token Storage

    func saveGoogleUserIdentifier(_ identifier: String, for email: String) throws {
        try saveIdentifier(identifier, for: email, serviceSuffix: "google")
        AppLogger.logAuth("Google user identifier saved to Keychain")
    }

    func retrieveGoogleUserIdentifier(for email: String) throws -> String {
        try retrieveIdentifier(for: email, serviceSuffix: "google")
    }

    func deleteGoogleUserIdentifier(for email: String) throws {
        try deleteIdentifier(for: email, serviceSuffix: "google")
    }
}
