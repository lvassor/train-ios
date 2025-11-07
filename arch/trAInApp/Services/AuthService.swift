//
//  AuthService.swift
//  trAInApp
//
//  Offline authentication service for MVP testing
//

import Foundation
import Combine

class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false

    private let usersKey = "train_users"
    private let currentUserIdKey = "train_current_user_id"

    // Hardcoded test accounts
    private let testAccounts = [
        ("test@test.com", "password123"),
        ("demo@train.com", "demo123"),
        ("user@example.com", "user123")
    ]

    private init() {
        loadSession()
    }

    // MARK: - Session Management

    func loadSession() {
        if let userId = UserDefaults.standard.string(forKey: currentUserIdKey) {
            if let user = loadUser(id: userId) {
                currentUser = user
                isAuthenticated = true
                print("Session restored for user: \(user.email)")
            }
        }
    }

    func saveSession() {
        if let user = currentUser {
            UserDefaults.standard.set(user.id, forKey: currentUserIdKey)
            saveUser(user)
        }
    }

    func clearSession() {
        UserDefaults.standard.removeObject(forKey: currentUserIdKey)
        currentUser = nil
        isAuthenticated = false
        print("Session cleared")
    }

    // MARK: - Authentication

    func login(email: String, password: String) -> Result<User, AuthError> {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)

        // First check test accounts
        if let testAccount = testAccounts.first(where: { $0.0 == normalizedEmail && $0.1 == password }) {
            // Check if user already exists in storage
            if let existingUser = findUser(byEmail: testAccount.0) {
                var updatedUser = existingUser
                updatedUser.lastLoginAt = Date()
                currentUser = updatedUser
                isAuthenticated = true
                saveSession()
                return .success(updatedUser)
            } else {
                // Create new user for test account
                let newUser = User(email: testAccount.0, password: testAccount.1)
                currentUser = newUser
                isAuthenticated = true
                saveSession()
                return .success(newUser)
            }
        }

        // Check stored users
        if let user = findUser(byEmail: normalizedEmail) {
            if user.password == password {
                var updatedUser = user
                updatedUser.lastLoginAt = Date()
                currentUser = updatedUser
                isAuthenticated = true
                saveSession()
                return .success(updatedUser)
            } else {
                return .failure(.invalidCredentials)
            }
        }

        return .failure(.userNotFound)
    }

    func signup(email: String, password: String) -> Result<User, AuthError> {
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
        if findUser(byEmail: normalizedEmail) != nil {
            return .failure(.emailAlreadyExists)
        }

        // Create new user
        let newUser = User(email: normalizedEmail, password: password)
        currentUser = newUser
        isAuthenticated = true
        saveSession()

        return .success(newUser)
    }

    func logout() {
        clearSession()
    }

    // MARK: - User Management

    func updateUser(_ user: User) {
        currentUser = user
        saveSession()
    }

    func updateQuestionnaireData(_ data: QuestionnaireData) {
        guard var user = currentUser else { return }
        user.questionnaireData = data
        updateUser(user)
    }

    func updateProgram(_ program: UserProgram) {
        guard var user = currentUser else { return }
        user.currentProgram = program
        updateUser(user)
    }

    func addWorkoutSession(_ session: WorkoutSession) {
        guard var user = currentUser else { return }
        user.workoutHistory.append(session)
        updateUser(user)
    }

    // MARK: - Storage

    private func saveUser(_ user: User) {
        var users = loadAllUsers()
        // Remove existing user with same ID
        users.removeAll { $0.id == user.id }
        // Add updated user
        users.append(user)

        if let encoded = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(encoded, forKey: usersKey)
        }
    }

    private func loadUser(id: String) -> User? {
        let users = loadAllUsers()
        return users.first { $0.id == id }
    }

    private func findUser(byEmail email: String) -> User? {
        let users = loadAllUsers()
        return users.first { $0.email.lowercased() == email.lowercased() }
    }

    private func loadAllUsers() -> [User] {
        guard let data = UserDefaults.standard.data(forKey: usersKey),
              let users = try? JSONDecoder().decode([User].self, from: data) else {
            return []
        }
        return users
    }
}

enum AuthError: LocalizedError {
    case invalidEmail
    case passwordTooShort
    case emailAlreadyExists
    case userNotFound
    case invalidCredentials

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
        }
    }
}
