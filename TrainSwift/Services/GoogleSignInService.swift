//
//  GoogleSignInService.swift
//  TrainSwift
//
//  Google Sign-In authentication service
//  Handles Google authentication flow
//
//  TODO: Add Google Sign-In SDK to project dependencies:
//  1. In Xcode, go to File > Add Package Dependencies
//  2. Add https://github.com/google/GoogleSignIn-iOS
//  3. Uncomment the import statements and implementation below
//  4. Add GoogleService-Info.plist to the project
//  5. Configure URL schemes in Info.plist
//

import Foundation
import Combine

// Uncomment when GoogleSignIn SDK is added:
// import GoogleSignIn

class GoogleSignInService: NSObject, ObservableObject {
    static let shared = GoogleSignInService()

    @Published var isSigningIn = false
    @Published var error: Error?

    // Completion handler for async sign-in
    private var completionHandler: ((Result<GoogleSignInResult, Error>) -> Void)?

    private override init() {
        super.init()
    }

    // MARK: - Configuration

    func configure() {
        // TODO: Configure Google Sign-In when SDK is added
        // guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") else {
        //     print("GoogleService-Info.plist not found")
        //     return
        // }
        //
        // guard let plist = NSDictionary(contentsOfFile: path),
        //       let clientId = plist["CLIENT_ID"] as? String else {
        //     print("CLIENT_ID not found in GoogleService-Info.plist")
        //     return
        // }
        //
        // GoogleSignIn.shared.configuration = GIDConfiguration(clientID: clientId)
        AppLogger.logAuth("GoogleSignInService: SDK not integrated yet", level: .warning)
    }

    // MARK: - Sign In Request

    func signIn(completion: @escaping (Result<GoogleSignInResult, Error>) -> Void) {
        self.completionHandler = completion
        self.isSigningIn = true
        self.error = nil

        // TODO: Implement when GoogleSignIn SDK is added
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isSigningIn = false
            // For now, show an informative error that won't break the navigation flow
            completion(.failure(GoogleSignInError.notImplemented))
        }

        // When SDK is added, use:
        // guard let presentingViewController = UIApplication.shared.windows.first?.rootViewController else {
        //     completion(.failure(GoogleSignInError.noPresentingViewController))
        //     return
        // }
        //
        // GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
        //     self.isSigningIn = false
        //
        //     if let error = error {
        //         completion(.failure(error))
        //         return
        //     }
        //
        //     guard let result = result,
        //           let user = result.user,
        //           let profile = user.profile else {
        //         completion(.failure(GoogleSignInError.invalidCredential))
        //         return
        //     }
        //
        //     let googleResult = GoogleSignInResult(
        //         userID: user.userID ?? "",
        //         email: profile.email,
        //         fullName: profile.name,
        //         givenName: profile.givenName,
        //         familyName: profile.familyName,
        //         profileImageURL: profile.imageURL(withDimension: 200)
        //     )
        //
        //     completion(.success(googleResult))
        // }
    }

    // MARK: - Sign Out

    func signOut() {
        // TODO: Implement when GoogleSignIn SDK is added
        // GIDSignIn.sharedInstance.signOut()
        AppLogger.logAuth("GoogleSignInService: Sign out not implemented yet", level: .warning)
    }

    // MARK: - Check Authentication State

    func checkPreviousSignIn(completion: @escaping (GoogleSignInResult?) -> Void) {
        // TODO: Implement when GoogleSignIn SDK is added
        // GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
        //     guard let user = user, let profile = user.profile else {
        //         completion(nil)
        //         return
        //     }
        //
        //     let result = GoogleSignInResult(
        //         userID: user.userID ?? "",
        //         email: profile.email,
        //         fullName: profile.name,
        //         givenName: profile.givenName,
        //         familyName: profile.familyName,
        //         profileImageURL: profile.imageURL(withDimension: 200)
        //     )
        //
        //     completion(result)
        // }
        completion(nil)
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
    case notImplemented
    case invalidCredential
    case noPresentingViewController
    case cancelled
    case unknown

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "Google Sign-In SDK not integrated yet. Coming soon!"
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