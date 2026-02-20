//
//  MockKeychainTests.swift
//  TrainSwiftTests
//
//  Tests using MockKeychainService to verify protocol conformance
//  and demonstrate mock-based testing patterns
//

import XCTest
@testable import TrainSwift

final class MockKeychainTests: XCTestCase {

    private var mockKeychain: MockKeychainService!

    override func setUp() {
        super.setUp()
        mockKeychain = MockKeychainService()
    }

    override func tearDown() {
        mockKeychain.reset()
        super.tearDown()
    }

    // MARK: - Password Operations via Protocol

    func testSaveAndVerifyViaProtocol() throws {
        let keychain: KeychainServiceProtocol = mockKeychain

        try keychain.savePassword("test123!", for: "user@test.com")
        XCTAssertTrue(keychain.verifyPassword("test123!", for: "user@test.com"))
        XCTAssertFalse(keychain.verifyPassword("wrong!", for: "user@test.com"))
    }

    func testSavePasswordCallTracking() throws {
        XCTAssertFalse(mockKeychain.savePasswordCalled)

        try mockKeychain.savePassword("pass1!", for: "user@test.com")
        XCTAssertTrue(mockKeychain.savePasswordCalled)
    }

    func testVerifyPasswordCallTracking() {
        XCTAssertFalse(mockKeychain.verifyPasswordCalled)

        _ = mockKeychain.verifyPassword("pass1!", for: "user@test.com")
        XCTAssertTrue(mockKeychain.verifyPasswordCalled)
    }

    // MARK: - Error Injection

    func testSaveThrowsWhenConfigured() {
        mockKeychain.shouldThrowOnSave = true

        XCTAssertThrowsError(try mockKeychain.savePassword("pass1!", for: "user@test.com")) { error in
            XCTAssertTrue(error is KeychainError)
        }
    }

    func testDeleteThrowsWhenConfigured() {
        mockKeychain.shouldThrowOnDelete = true

        XCTAssertThrowsError(try mockKeychain.deletePassword(for: "user@test.com")) { error in
            XCTAssertTrue(error is KeychainError)
        }
    }

    // MARK: - Email Case Insensitivity

    func testEmailNormalisedToLowercase() throws {
        try mockKeychain.savePassword("pass1!", for: "User@Example.COM")
        XCTAssertTrue(mockKeychain.verifyPassword("pass1!", for: "user@example.com"),
                       "Mock should normalise emails to lowercase")
    }

    // MARK: - Apple/Google Identifier Operations

    func testAppleIdentifierSaveAndRetrieve() throws {
        try mockKeychain.saveAppleUserIdentifier("apple-id-123", for: "user@test.com")
        let retrieved = try mockKeychain.retrieveAppleUserIdentifier(for: "user@test.com")
        XCTAssertEqual(retrieved, "apple-id-123")
    }

    func testAppleIdentifierNotFound() {
        XCTAssertThrowsError(try mockKeychain.retrieveAppleUserIdentifier(for: "noone@test.com")) { error in
            guard case KeychainError.itemNotFound = error else {
                XCTFail("Expected itemNotFound error")
                return
            }
        }
    }

    func testGoogleIdentifierSaveAndRetrieve() throws {
        try mockKeychain.saveGoogleUserIdentifier("google-id-456", for: "user@test.com")
        let retrieved = try mockKeychain.retrieveGoogleUserIdentifier(for: "user@test.com")
        XCTAssertEqual(retrieved, "google-id-456")
    }

    func testDeleteAppleIdentifier() throws {
        try mockKeychain.saveAppleUserIdentifier("apple-id", for: "user@test.com")
        try mockKeychain.deleteAppleUserIdentifier(for: "user@test.com")

        XCTAssertThrowsError(try mockKeychain.retrieveAppleUserIdentifier(for: "user@test.com"))
    }

    // MARK: - Reset

    func testResetClearsEverything() throws {
        try mockKeychain.savePassword("pass!", for: "user@test.com")
        try mockKeychain.saveAppleUserIdentifier("apple", for: "user@test.com")
        try mockKeychain.saveGoogleUserIdentifier("google", for: "user@test.com")

        mockKeychain.reset()

        XCTAssertFalse(mockKeychain.verifyPassword("pass!", for: "user@test.com"))
        XCTAssertThrowsError(try mockKeychain.retrieveAppleUserIdentifier(for: "user@test.com"))
        XCTAssertThrowsError(try mockKeychain.retrieveGoogleUserIdentifier(for: "user@test.com"))
        XCTAssertFalse(mockKeychain.savePasswordCalled)
    }
}
