//
//  AuthService.swift
//  trAInSwift
//
//  Authentication service using Core Data + Keychain
//  Supports email/password and Sign in with Apple
//  Passwords stored securely (hashed) in Keychain
//

import Foundation
import Combine
import CoreData

class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: UserProfile?
    @Published var isAuthenticated: Bool = false

    private let keychain = KeychainService.shared
    private let appleSignIn = AppleSignInService.shared
    private let googleSignIn = GoogleSignInService.shared
    private let persistence = PersistenceController.shared
    private var context: NSManagedObjectContext {
        persistence.container.viewContext
    }

    private let currentUserIdKey = "train_current_user_id"

    private init() {
        loadSession()
    }

    // MARK: - Session Management

    func loadSession() {
        if let userIdString = UserDefaults.standard.string(forKey: currentUserIdKey),
           let userId = UUID(uuidString: userIdString) {
            if let user = UserProfile.fetch(byId: userId, context: context) {
                currentUser = user
                isAuthenticated = true
                AppLogger.logAuth("Session restored for user")
            }
        }
    }

    func saveSession() {
        guard let user = currentUser else { return }

        UserDefaults.standard.set(user.id?.uuidString, forKey: currentUserIdKey)
        do {
            try context.save()
            AppLogger.logAuth("User session saved successfully")
        } catch {
            AppLogger.logAuth("Failed to save user session: \(error.localizedDescription)", level: .error)
        }
    }

    func clearSession() {
        UserDefaults.standard.removeObject(forKey: currentUserIdKey)
        currentUser = nil
        isAuthenticated = false
        AppLogger.logAuth("Session cleared")
    }

    // MARK: - Email/Password Authentication

    func login(email: String, password: String) -> Result<UserProfile, AuthError> {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)

        // Check stored users
        guard let user = UserProfile.fetch(byEmail: normalizedEmail, context: context) else {
            AppLogger.logAuth("Login failed: user not found", level: .notice)
            return .failure(.userNotFound)
        }

        // Check if this is an Apple Sign In user (no password stored)
        if user.isAppleUser {
            AppLogger.logAuth("Login failed: user signed up with Apple", level: .notice)
            return .failure(.useAppleSignIn)
        }

        // Check if this is a Google Sign In user (no password stored)
        if user.isGoogleUser {
            AppLogger.logAuth("Login failed: user signed up with Google", level: .notice)
            return .failure(.useGoogleSignIn)
        }

        // Verify password from Keychain (passwords are hashed)
        if keychain.verifyPassword(password, for: normalizedEmail) {
            user.updateLastLogin()
            currentUser = user
            isAuthenticated = true
            saveSession()
            AppLogger.logAuth("User logged in successfully")
            return .success(user)
        } else {
            AppLogger.logAuth("Login failed: invalid credentials", level: .notice)
            return .failure(.invalidCredentials)
        }
    }

    func signup(email: String, password: String, name: String = "") -> Result<UserProfile, AuthError> {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)

        // Validate email format
        guard isValidEmail(normalizedEmail) else {
            return .failure(.invalidEmail)
        }

        // Validate password (min 6 chars, must contain number and special char)
        guard isValidPassword(password) else {
            return .failure(.passwordTooWeak)
        }

        // Check if user already exists
        if UserProfile.fetch(byEmail: normalizedEmail, context: context) != nil {
            return .failure(.emailAlreadyExists)
        }

        // Create new user
        let newUser = UserProfile.create(email: normalizedEmail, context: context)
        newUser.name = name
        newUser.isAppleUser = false

        // Save hashed password to Keychain
        do {
            try keychain.savePassword(password, for: normalizedEmail)
        } catch {
            // Rollback user creation if password save fails
            context.delete(newUser)
            return .failure(.keychainError)
        }

        currentUser = newUser
        isAuthenticated = true
        saveSession()

        AppLogger.logAuth("New user signed up successfully")
        return .success(newUser)
    }

    // MARK: - Sign in with Apple

    func signInWithApple(completion: @escaping (Result<UserProfile, AuthError>) -> Void) {
        appleSignIn.signIn { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let appleResult):
                    self.handleAppleSignInResult(appleResult, completion: completion)
                case .failure(let error):
                    if (error as NSError).code == 1001 {
                        // User cancelled
                        completion(.failure(.cancelled))
                    } else {
                        AppLogger.logAuth("Apple Sign In failed: \(error.localizedDescription)", level: .error)
                        completion(.failure(.appleSignInFailed))
                    }
                }
            }
        }
    }

    private func handleAppleSignInResult(_ result: AppleSignInResult, completion: @escaping (Result<UserProfile, AuthError>) -> Void) {
        let userIdentifier = result.userIdentifier

        // Check if user already exists by Apple user identifier
        if let existingUser = UserProfile.fetch(byAppleId: userIdentifier, context: context) {
            existingUser.updateLastLogin()
            currentUser = existingUser
            isAuthenticated = true
            saveSession()
            AppLogger.logAuth("Apple user logged in successfully")
            completion(.success(existingUser))
            return
        }

        // Check if user exists by email (linking accounts)
        if let email = result.email,
           let existingUser = UserProfile.fetch(byEmail: email.lowercased(), context: context) {
            // Link Apple ID to existing account
            existingUser.appleUserIdentifier = userIdentifier
            existingUser.isAppleUser = true
            existingUser.updateLastLogin()
            currentUser = existingUser
            isAuthenticated = true
            saveSession()
            AppLogger.logAuth("Linked Apple ID to existing account")
            completion(.success(existingUser))
            return
        }

        // Create new user with Apple credentials
        // Note: email may be nil on subsequent logins (Apple only provides it once)
        let email = result.email ?? "\(userIdentifier)@privaterelay.appleid.com"
        let newUser = UserProfile.create(email: email.lowercased(), context: context)
        newUser.name = result.fullName ?? ""
        newUser.appleUserIdentifier = userIdentifier
        newUser.isAppleUser = true

        // Store Apple identifier in Keychain
        do {
            try keychain.saveAppleUserIdentifier(userIdentifier, for: email)
        } catch {
            AppLogger.logAuth("Failed to save Apple identifier: \(error)", level: .warning)
            // Continue anyway - not critical
        }

        currentUser = newUser
        isAuthenticated = true
        saveSession()

        AppLogger.logAuth("New Apple user created successfully")
        completion(.success(newUser))
    }

    // MARK: - Sign in with Google

    func signInWithGoogle(completion: @escaping (Result<UserProfile, AuthError>) -> Void) {
        googleSignIn.signIn { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let googleResult):
                    self.handleGoogleSignInResult(googleResult, completion: completion)
                case .failure(let error):
                    if let googleError = error as? GoogleSignInError, googleError == .cancelled {
                        completion(.failure(.cancelled))
                    } else {
                        AppLogger.logAuth("Google Sign In failed: \(error.localizedDescription)", level: .error)
                        completion(.failure(.googleSignInFailed))
                    }
                }
            }
        }
    }

    private func handleGoogleSignInResult(_ result: GoogleSignInResult, completion: @escaping (Result<UserProfile, AuthError>) -> Void) {
        let userIdentifier = result.userID
        let email = result.email

        // Check if user already exists by Google user identifier
        if let existingUser = UserProfile.fetch(byGoogleId: userIdentifier, context: context) {
            existingUser.updateLastLogin()
            currentUser = existingUser
            isAuthenticated = true
            saveSession()
            AppLogger.logAuth("Google user logged in successfully")
            completion(.success(existingUser))
            return
        }

        // Check if user exists by email (linking accounts)
        if let existingUser = UserProfile.fetch(byEmail: email.lowercased(), context: context) {
            // Link Google ID to existing account
            existingUser.googleUserIdentifier = userIdentifier
            existingUser.isGoogleUser = true
            existingUser.updateLastLogin()
            currentUser = existingUser
            isAuthenticated = true
            saveSession()
            AppLogger.logAuth("Linked Google ID to existing account")
            completion(.success(existingUser))
            return
        }

        // Create new user with Google credentials
        let newUser = UserProfile.create(email: email.lowercased(), context: context)
        newUser.name = result.fullName ?? ""
        newUser.googleUserIdentifier = userIdentifier
        newUser.isGoogleUser = true

        // Store Google identifier in Keychain
        do {
            try keychain.saveGoogleUserIdentifier(userIdentifier, for: email)
        } catch {
            AppLogger.logAuth("Failed to save Google identifier: \(error)", level: .warning)
            // Continue anyway - not critical
        }

        currentUser = newUser
        isAuthenticated = true
        saveSession()

        AppLogger.logAuth("New Google user created successfully")
        completion(.success(newUser))
    }

    func logout() {
        googleSignIn.signOut()
        clearSession()
    }

    // MARK: - Validation Helpers

    private func isValidEmail(_ email: String) -> Bool {
        // RFC 5322 simplified validation
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func isValidPassword(_ password: String) -> Bool {
        // Minimum 6 characters, must contain at least one number and one special character
        guard password.count >= 6 else { return false }
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSpecial = password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:',.<>?/~`")) != nil
        return hasNumber && hasSpecial
    }

    // MARK: - User Management

    func updateUser(_ user: UserProfile) {
        currentUser = user
        saveSession()
    }

    func updateQuestionnaireData(_ data: QuestionnaireData) {
        guard let user = currentUser else { return }
        user.setQuestionnaireData(data)

        // Also update related fields
        user.age = Int16(data.age)
        user.weight = data.weightUnit == .kg ? data.weightKg : data.weightLbs
        user.height = data.heightUnit == .cm ? data.heightCm : Double(data.heightFt * 12 + data.heightIn) * 2.54
        user.experience = data.experienceLevel
        user.equipmentArray = data.equipmentAvailable
        user.injuriesArray = data.injuries
        user.priorityMusclesArray = data.targetMuscleGroups

        // Update user's name from questionnaire (overrides Apple Sign In name if set)
        if !data.name.isEmpty {
            user.name = data.name
        }

        saveSession()
    }

    func updateProgram(_ program: Program) {
        guard let user = currentUser, let userId = user.id else {
            AppLogger.logAuth("Cannot update program: no current user", level: .error)
            return
        }

        // Create new WorkoutProgram in Core Data
        _ = WorkoutProgram.create(userId: userId, program: program, context: context)
        saveSession()
        AppLogger.logProgram("Program updated successfully")
    }

    func getCurrentProgram() -> WorkoutProgram? {
        guard let user = currentUser, let userId = user.id else { return nil }
        return WorkoutProgram.fetchCurrent(forUserId: userId, context: context)
    }

    func addWorkoutSession(
        sessionName: String,
        weekNumber: Int,
        exercises: [LoggedExercise],
        durationMinutes: Int
    ) {
        guard let user = currentUser, let userId = user.id else {
            AppLogger.logWorkout("Cannot add workout session: no current user", level: .error)
            return
        }

        let programId = getCurrentProgram()?.id

        _ = CDWorkoutSession.create(
            userId: userId,
            programId: programId,
            sessionName: sessionName,
            weekNumber: weekNumber,
            exercises: exercises,
            durationMinutes: durationMinutes,
            context: context
        )

        do {
            try context.save()
            AppLogger.logWorkout("Workout session saved successfully")
        } catch {
            AppLogger.logWorkout("Failed to save workout session: \(error.localizedDescription)", level: .error)
        }
    }

    func getWorkoutHistory() -> [CDWorkoutSession] {
        guard let user = currentUser, let userId = user.id else { return [] }
        return CDWorkoutSession.fetchAll(forUserId: userId, context: context)
    }

    func completeCurrentSession() {
        guard let program = getCurrentProgram() else {
            AppLogger.logWorkout("Cannot complete session: no current program", level: .warning)
            return
        }
        program.completeSession()
        saveSession()
        AppLogger.logWorkout("Session marked as complete")
    }

    // MARK: - Previous Session Data

    /// Fetches the previous session's logged sets for a specific exercise
    /// Searches across ALL previous sessions to find most recent log of this exercise
    /// Used for rep counter and progression analysis
    func getPreviousSessionData(
        programId: String,
        exerciseName: String
    ) -> [LoggedSet]? {
        let fetchRequest: NSFetchRequest<CDWorkoutSession> = CDWorkoutSession.fetchRequest()

        // Query by program and date only (no session type filter needed - exercises don't repeat across session types)
        fetchRequest.predicate = NSPredicate(
            format: "programId == %@ AND completedAt < %@",
            programId, Date() as CVarArg
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "completedAt", ascending: false)]

        do {
            let results = try context.fetch(fetchRequest)

            // Iterate through sessions to find first one with this exercise
            for session in results {
                guard let exercisesData = session.exercisesData,
                      let loggedExercises = try? JSONDecoder().decode([LoggedExercise].self, from: exercisesData) else {
                    continue
                }

                if let matchingExercise = loggedExercises.first(where: { $0.exerciseName == exerciseName }) {
                    AppLogger.logWorkout("Found previous data for \(exerciseName): \(matchingExercise.sets.count) sets")
                    return matchingExercise.sets
                }
            }

            AppLogger.logWorkout("No previous data found for \(exerciseName)")
            return nil  // Exercise never logged before (Week 1 or always skipped)
        } catch {
            AppLogger.logDatabase("Failed to fetch previous session: \(error)", level: .error)
            return nil
        }
    }
}

enum AuthError: LocalizedError {
    case invalidEmail
    case passwordTooShort
    case passwordTooWeak
    case emailAlreadyExists
    case userNotFound
    case invalidCredentials
    case keychainError
    case useAppleSignIn
    case useGoogleSignIn
    case appleSignInFailed
    case googleSignInFailed
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .passwordTooShort:
            return "Password must be at least 6 characters"
        case .passwordTooWeak:
            return "Password must contain at least one number and one special character"
        case .emailAlreadyExists:
            return "An account with this email already exists"
        case .userNotFound:
            return "No account found with this email"
        case .invalidCredentials:
            return "Invalid email or password"
        case .keychainError:
            return "Failed to securely store password"
        case .useAppleSignIn:
            return "This account uses Sign in with Apple"
        case .useGoogleSignIn:
            return "This account uses Google Sign-In"
        case .appleSignInFailed:
            return "Sign in with Apple failed. Please try again."
        case .googleSignInFailed:
            return "Google Sign-In failed. Please try again."
        case .cancelled:
            return "Sign in was cancelled"
        }
    }
}
