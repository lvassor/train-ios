//
//  AuthValidationTests.swift
//  TrainSwiftTests
//
//  Unit tests for AuthService email and password validation
//

import XCTest
@testable import TrainSwift

final class AuthValidationTests: XCTestCase {

    private var authService: AuthService!

    @MainActor
    override func setUp() {
        super.setUp()
        authService = AuthService.shared
    }

    // MARK: - Email Validation

    @MainActor
    func testValidEmailAccepted() {
        XCTAssertTrue(authService.isValidEmail("user@example.com"))
        XCTAssertTrue(authService.isValidEmail("test.user@domain.co.uk"))
        XCTAssertTrue(authService.isValidEmail("name+tag@gmail.com"))
        XCTAssertTrue(authService.isValidEmail("user123@test.io"))
    }

    @MainActor
    func testInvalidEmailRejected() {
        XCTAssertFalse(authService.isValidEmail(""))
        XCTAssertFalse(authService.isValidEmail("notanemail"))
        XCTAssertFalse(authService.isValidEmail("@domain.com"))
        XCTAssertFalse(authService.isValidEmail("user@"))
        XCTAssertFalse(authService.isValidEmail("user@.com"))
        XCTAssertFalse(authService.isValidEmail("user @example.com"))
    }

    @MainActor
    func testEmailWithSpecialCharactersAccepted() {
        XCTAssertTrue(authService.isValidEmail("user.name@example.com"))
        XCTAssertTrue(authService.isValidEmail("user_name@example.com"))
        XCTAssertTrue(authService.isValidEmail("user-name@example.com"))
        XCTAssertTrue(authService.isValidEmail("user%name@example.com"))
    }

    // MARK: - Password Validation

    @MainActor
    func testValidPasswordAccepted() {
        // 6+ chars, has number, has special character
        XCTAssertTrue(authService.isValidPassword("pass1!"))
        XCTAssertTrue(authService.isValidPassword("MyP@ss1"))
        XCTAssertTrue(authService.isValidPassword("Str0ng!Password"))
        XCTAssertTrue(authService.isValidPassword("abc123!@#"))
    }

    @MainActor
    func testPasswordTooShortRejected() {
        XCTAssertFalse(authService.isValidPassword(""))
        XCTAssertFalse(authService.isValidPassword("a1!"))
        XCTAssertFalse(authService.isValidPassword("ab1!"))
        XCTAssertFalse(authService.isValidPassword("abc1!"))
    }

    @MainActor
    func testPasswordWithoutNumberRejected() {
        XCTAssertFalse(authService.isValidPassword("abcdef!"))
        XCTAssertFalse(authService.isValidPassword("Password!"))
    }

    @MainActor
    func testPasswordWithoutSpecialCharRejected() {
        XCTAssertFalse(authService.isValidPassword("abcdef1"))
        XCTAssertFalse(authService.isValidPassword("Password1"))
    }

    @MainActor
    func testPasswordExactlyMinimumLength() {
        // Exactly 6 characters with number and special char
        XCTAssertTrue(authService.isValidPassword("abc1!d"))
        // 5 characters — too short
        XCTAssertFalse(authService.isValidPassword("ab1!d"))
    }
}
