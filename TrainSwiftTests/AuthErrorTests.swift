//
//  AuthErrorTests.swift
//  TrainSwiftTests
//
//  Tests for AuthError localised descriptions
//

import XCTest
@testable import TrainSwift

final class AuthErrorTests: XCTestCase {

    // MARK: - Error Descriptions Not Nil

    func testAllAuthErrorsHaveDescriptions() {
        let errors: [AuthError] = [
            .invalidEmail,
            .passwordTooShort,
            .passwordTooWeak,
            .emailAlreadyExists,
            .userNotFound,
            .invalidCredentials,
            .keychainError,
            .useAppleSignIn,
            .useGoogleSignIn,
            .appleSignInFailed,
            .googleSignInFailed,
            .cancelled
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription,
                            "\(error) should have an error description")
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true,
                            "\(error) should have a non-empty description")
        }
    }

    // MARK: - Specific Error Messages

    func testInvalidEmailMessage() {
        let error = AuthError.invalidEmail
        XCTAssertTrue(error.errorDescription?.contains("email") ?? false,
                       "Invalid email error should mention 'email'")
    }

    func testPasswordTooShortMessage() {
        let error = AuthError.passwordTooShort
        XCTAssertTrue(error.errorDescription?.contains("6") ?? false,
                       "Password too short error should mention minimum length")
    }

    func testPasswordTooWeakMessage() {
        let error = AuthError.passwordTooWeak
        XCTAssertTrue(error.errorDescription?.contains("number") ?? false,
                       "Password too weak error should mention number requirement")
    }

    func testEmailAlreadyExistsMessage() {
        let error = AuthError.emailAlreadyExists
        XCTAssertTrue(error.errorDescription?.contains("exists") ?? false,
                       "Email already exists error should mention 'exists'")
    }

    // MARK: - LocalizedError Conformance

    func testAuthErrorConformsToLocalizedError() {
        let error: LocalizedError = AuthError.invalidEmail
        XCTAssertNotNil(error.errorDescription)
    }
}
