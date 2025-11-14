//
//  AuthService.swift
//  trAInSwift
//
//  Authentication service using Core Data + Keychain
//  Passwords stored securely in Keychain
//  User data stored in Core Data
//

import Foundation
import Combine
import CoreData

class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: UserProfile?
    @Published var isAuthenticated: Bool = false

    private let keychain = KeychainService.shared
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

    // MARK: - Authentication

    func login(email: String, password: String) -> Result<UserProfile, AuthError> {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)

        #if DEBUG
        // Check test accounts first - but NO automatic program creation
        // All users, including test accounts, MUST complete the questionnaire
        if TestAccounts.isTestAccount(email: normalizedEmail),
           let testPassword = TestAccounts.getPassword(for: normalizedEmail),
           testPassword == password {
            // Check if user already exists in Core Data
            if let existingUser = UserProfile.fetch(byEmail: normalizedEmail, context: context) {
                existingUser.updateLastLogin()
                currentUser = existingUser
                isAuthenticated = true
                saveSession()
                AppLogger.logAuth("Test user logged in successfully")
                return .success(existingUser)
            } else {
                // Create new test user WITHOUT any program
                // They must go through questionnaire like everyone else
                let newUser = UserProfile.create(email: normalizedEmail, context: context)
                do {
                    try keychain.savePassword(testPassword, for: normalizedEmail)
                } catch {
                    AppLogger.logAuth("Failed to save test password to keychain: \(error.localizedDescription)", level: .warning)
                }

                currentUser = newUser
                isAuthenticated = true
                saveSession()
                AppLogger.logAuth("New test user created - must complete questionnaire")
                return .success(newUser)
            }
        }
        #endif

        // Check stored users
        guard let user = UserProfile.fetch(byEmail: normalizedEmail, context: context) else {
            AppLogger.logAuth("Login failed: user not found", level: .notice)
            return .failure(.userNotFound)
        }

        // Verify password from Keychain
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

        // Validate email
        guard normalizedEmail.contains("@") && normalizedEmail.contains(".") else {
            return .failure(.invalidEmail)
        }

        // Validate password
        guard password.count >= 6 else {
            return .failure(.passwordTooShort)
        }

        // Check if user already exists
        if UserProfile.fetch(byEmail: normalizedEmail, context: context) != nil {
            return .failure(.emailAlreadyExists)
        }

        // Create new user
        let newUser = UserProfile.create(email: normalizedEmail, context: context)
        newUser.name = name

        // Save password to Keychain
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

        return .success(newUser)
    }

    func logout() {
        clearSession()
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
}

enum AuthError: LocalizedError {
    case invalidEmail
    case passwordTooShort
    case emailAlreadyExists
    case userNotFound
    case invalidCredentials
    case keychainError

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .passwordTooShort:
            return "Password must be at least 6 characters"
        case .emailAlreadyExists:
            return "An account with this email already exists"
        case .userNotFound:
            return "No account found with this email"
        case .invalidCredentials:
            return "Invalid email or password"
        case .keychainError:
            return "Failed to securely store password"
        }
    }
}
