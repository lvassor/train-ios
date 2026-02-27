//
//  AppleSignInService.swift
//  TrainSwift
//
//  Sign in with Apple authentication service
//  Handles Apple ID authentication flow
//

import Foundation
import AuthenticationServices
import CryptoKit
import Combine

@MainActor
class AppleSignInService: NSObject, ObservableObject {
    static let shared = AppleSignInService()

    @Published var isSigningIn = false
    @Published var error: Error?

    // Completion handler for async sign-in
    private var completionHandler: ((Result<AppleSignInResult, Error>) -> Void)?

    private override init() {
        super.init()
    }

    // MARK: - Sign In Request

    func signIn(completion: @escaping (Result<AppleSignInResult, Error>) -> Void) {
        self.completionHandler = completion
        self.isSigningIn = true
        self.error = nil

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        // Generate nonce for security
        let nonce: String
        do {
            nonce = try randomNonceString()
        } catch {
            isSigningIn = false
            completion(.failure(AppleSignInError.nonceGenerationFailed))
            return
        }
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    // MARK: - Check Credential State

    func checkCredentialState(userID: String, completion: @escaping (ASAuthorizationAppleIDProvider.CredentialState) -> Void) {
        ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { state, error in
            Task { @MainActor in
                completion(state)
            }
        }
    }

    // MARK: - Nonce Generation (for security)

    private func randomNonceString(length: Int = 32) throws -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        guard errorCode == errSecSuccess else {
            throw AppleSignInError.nonceGenerationFailed
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        isSigningIn = false

        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            completionHandler?(.failure(AppleSignInError.invalidCredential))
            return
        }

        // Extract user info
        let userIdentifier = appleIDCredential.user
        let email = appleIDCredential.email // Only provided on first sign-in
        let fullName = appleIDCredential.fullName

        // Build display name
        var displayName: String? = nil
        if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
            displayName = "\(givenName) \(familyName)"
        } else if let givenName = fullName?.givenName {
            displayName = givenName
        }

        let result = AppleSignInResult(
            userIdentifier: userIdentifier,
            email: email,
            fullName: displayName
        )

        // Store the user identifier for future credential checks
        UserDefaults.standard.set(userIdentifier, forKey: "appleUserIdentifier")

        completionHandler?(.success(result))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        isSigningIn = false
        self.error = error
        completionHandler?(.failure(error))
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleSignInService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return UIWindow()
        }
        return window
    }
}

// MARK: - Supporting Types

struct AppleSignInResult {
    let userIdentifier: String
    let email: String?
    let fullName: String?
}

enum AppleSignInError: LocalizedError {
    case invalidCredential
    case cancelled
    case nonceGenerationFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid Apple ID credential"
        case .cancelled:
            return "Sign in was cancelled"
        case .nonceGenerationFailed:
            return "Failed to generate security nonce for Apple Sign In"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
