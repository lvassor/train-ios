//
//  GoogleSignInService.swift
//  TrainSwift
//
//  Google Sign-In authentication service
//  Handles Google authentication flow via GoogleSignIn SDK
//

import Foundation
import Combine
import GoogleSignIn

class GoogleSignInService: NSObject, ObservableObject {
    static let shared = GoogleSignInService()

    @Published var isSigningIn = false
    @Published var error: Error?

    private var completionHandler: ((Result<GoogleSignInResult, Error>) -> Void)?

    private override init() {
        super.init()
    }

    // MARK: - Configuration

    func configure() {
        // Client ID is set via Info.plist GIDClientID key
        // No runtime configuration needed with the modern SDK
        AppLogger.logAuth("GoogleSignInService configured")
    }

    // MARK: - Handle URL callback

    func handle(_ url: URL) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    // MARK: - Sign In Request

    func signIn(completion: @escaping (Result<GoogleSignInResult, Error>) -> Void) {
        self.completionHandler = completion
        self.isSigningIn = true
        self.error = nil

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            isSigningIn = false
            completion(.failure(GoogleSignInError.noPresentingViewController))
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { [weak self] result, error in
            guard let self else { return }
            self.isSigningIn = false

            if let error {
                if (error as NSError).code == GIDSignInError.canceled.rawValue {
                    completion(.failure(GoogleSignInError.cancelled))
                } else {
                    completion(.failure(error))
                }
                return
            }

            guard let user = result?.user,
                  let profile = user.profile else {
                completion(.failure(GoogleSignInError.invalidCredential))
                return
            }

            let googleResult = GoogleSignInResult(
                userID: user.userID ?? "",
                email: profile.email,
                fullName: profile.name,
                givenName: profile.givenName,
                familyName: profile.familyName,
                profileImageURL: profile.imageURL(withDimension: 200)
            )

            completion(.success(googleResult))
        }
    }

    // MARK: - Sign Out

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        AppLogger.logAuth("Google Sign-In: signed out")
    }

    // MARK: - Check Authentication State

    func checkPreviousSignIn(completion: @escaping (GoogleSignInResult?) -> Void) {
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            guard let user, let profile = user.profile else {
                completion(nil)
                return
            }

            let result = GoogleSignInResult(
                userID: user.userID ?? "",
                email: profile.email,
                fullName: profile.name,
                givenName: profile.givenName,
                familyName: profile.familyName,
                profileImageURL: profile.imageURL(withDimension: 200)
            )

            completion(result)
        }
    }
}

// MARK: - Supporting Types

struct GoogleSignInResult {
    let userID: String
    let email: String
    let fullName: String?
    let givenName: String?
    let familyName: String?
    let profileImageURL: URL?
}

enum GoogleSignInError: LocalizedError {
    case invalidCredential
    case noPresentingViewController
    case cancelled
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid Google credential"
        case .noPresentingViewController:
            return "No presenting view controller available"
        case .cancelled:
            return "Sign in was cancelled"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
