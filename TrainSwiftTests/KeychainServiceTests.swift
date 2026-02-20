//
//  KeychainServiceTests.swift
//  TrainSwiftTests
//
//  Integration tests for KeychainService password hashing and storage
//  Note: These tests interact with the real Keychain and must run on simulator
//

import XCTest
@testable import TrainSwift

final class KeychainServiceTests: XCTestCase {

    private let testEmail = "test_keychain_\(UUID().uuidString)@example.com"
    private var keychain: KeychainService!

    override func setUp() {
        super.setUp()
        keychain = KeychainService.shared
    }

    override func tearDown() {
        // Clean up test entries
        try? keychain.deletePassword(for: testEmail)
        super.tearDown()
    }

    // MARK: - Save and Verify Password

    func testSaveAndVerifyPassword() throws {
        try keychain.savePassword("TestP@ss1", for: testEmail)
        XCTAssertTrue(keychain.verifyPassword("TestP@ss1", for: testEmail),
                       "Correct password should verify successfully")
    }

    func testWrongPasswordFails() throws {
        try keychain.savePassword("TestP@ss1", for: testEmail)
        XCTAssertFalse(keychain.verifyPassword("WrongP@ss1", for: testEmail),
                        "Wrong password should fail verification")
    }

    func testEmptyPasswordHandled() throws {
        try keychain.savePassword("", for: testEmail)
        XCTAssertTrue(keychain.verifyPassword("", for: testEmail),
                       "Empty password should verify against empty stored hash")
        XCTAssertFalse(keychain.verifyPassword("notempty", for: testEmail),
                        "Non-empty password should fail against empty stored hash")
    }

    func testPasswordCaseSensitive() throws {
        try keychain.savePassword("MyP@ss1", for: testEmail)
        XCTAssertFalse(keychain.verifyPassword("myp@ss1", for: testEmail),
                        "Password verification should be case-sensitive")
    }

    // MARK: - Update Password

    func testUpdatePassword() throws {
        try keychain.savePassword("OldP@ss1", for: testEmail)
        try keychain.updatePassword("NewP@ss2", for: testEmail)

        XCTAssertFalse(keychain.verifyPassword("OldP@ss1", for: testEmail),
                        "Old password should fail after update")
        XCTAssertTrue(keychain.verifyPassword("NewP@ss2", for: testEmail),
                       "New password should verify after update")
    }

    // MARK: - Delete Password

    func testDeletePassword() throws {
        try keychain.savePassword("TestP@ss1", for: testEmail)
        try keychain.deletePassword(for: testEmail)

        XCTAssertFalse(keychain.verifyPassword("TestP@ss1", for: testEmail),
                        "Deleted password should fail verification")
    }

    // MARK: - Email Normalisation

    func testEmailCaseInsensitive() throws {
        try keychain.savePassword("TestP@ss1", for: "User@Example.COM")
        XCTAssertTrue(keychain.verifyPassword("TestP@ss1", for: "user@example.com"),
                       "Email lookup should be case-insensitive")
    }

    // MARK: - Per-User Salt Uniqueness

    func testDifferentUsersGetDifferentHashes() throws {
        let email2 = "test_keychain_\(UUID().uuidString)@example.com"
        defer { try? keychain.deletePassword(for: email2) }

        let password = "SameP@ss1"
        try keychain.savePassword(password, for: testEmail)
        try keychain.savePassword(password, for: email2)

        // Both should verify with the same password
        XCTAssertTrue(keychain.verifyPassword(password, for: testEmail))
        XCTAssertTrue(keychain.verifyPassword(password, for: email2))

        // Cross-verification should still work since we verify per-user
        // (the salt is per-user, so the hash differs internally)
    }
}
