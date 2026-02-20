//
//  MockKeychainService.swift
//  TrainSwiftTests
//
//  Mock KeychainService for unit testing auth flows without real Keychain
//

import Foundation
@testable import TrainSwift

/// In-memory mock of KeychainServiceProtocol for testing
class MockKeychainService: KeychainServiceProtocol {

    // In-memory storage
    private var passwords: [String: String] = [:]  // email → hash
    private var appleIdentifiers: [String: String] = [:]
    private var googleIdentifiers: [String: String] = [:]

    var savePasswordCalled = false
    var verifyPasswordCalled = false
    var deletePasswordCalled = false

    // Track errors to inject
    var shouldThrowOnSave = false
    var shouldThrowOnDelete = false

    // MARK: - Password Operations

    func savePassword(_ password: String, for email: String) throws {
        savePasswordCalled = true
        if shouldThrowOnSave {
            throw KeychainError.unknown(-1)
        }
        passwords[email.lowercased()] = password
    }

    func verifyPassword(_ password: String, for email: String) -> Bool {
        verifyPasswordCalled = true
        return passwords[email.lowercased()] == password
    }

    func updatePassword(_ newPassword: String, for email: String) throws {
        if shouldThrowOnSave {
            throw KeychainError.unknown(-1)
        }
        passwords[email.lowercased()] = newPassword
    }

    func deletePassword(for email: String) throws {
        deletePasswordCalled = true
        if shouldThrowOnDelete {
            throw KeychainError.unknown(-1)
        }
        passwords.removeValue(forKey: email.lowercased())
    }

    // MARK: - Apple Sign In

    func saveAppleUserIdentifier(_ identifier: String, for email: String) throws {
        if shouldThrowOnSave { throw KeychainError.unknown(-1) }
        appleIdentifiers[email.lowercased()] = identifier
    }

    func retrieveAppleUserIdentifier(for email: String) throws -> String {
        guard let id = appleIdentifiers[email.lowercased()] else {
            throw KeychainError.itemNotFound
        }
        return id
    }

    func deleteAppleUserIdentifier(for email: String) throws {
        if shouldThrowOnDelete { throw KeychainError.unknown(-1) }
        appleIdentifiers.removeValue(forKey: email.lowercased())
    }

    // MARK: - Google Sign In

    func saveGoogleUserIdentifier(_ identifier: String, for email: String) throws {
        if shouldThrowOnSave { throw KeychainError.unknown(-1) }
        googleIdentifiers[email.lowercased()] = identifier
    }

    func retrieveGoogleUserIdentifier(for email: String) throws -> String {
        guard let id = googleIdentifiers[email.lowercased()] else {
            throw KeychainError.itemNotFound
        }
        return id
    }

    func deleteGoogleUserIdentifier(for email: String) throws {
        if shouldThrowOnDelete { throw KeychainError.unknown(-1) }
        googleIdentifiers.removeValue(forKey: email.lowercased())
    }

    // MARK: - Helpers

    func reset() {
        passwords.removeAll()
        appleIdentifiers.removeAll()
        googleIdentifiers.removeAll()
        savePasswordCalled = false
        verifyPasswordCalled = false
        deletePasswordCalled = false
        shouldThrowOnSave = false
        shouldThrowOnDelete = false
    }
}
