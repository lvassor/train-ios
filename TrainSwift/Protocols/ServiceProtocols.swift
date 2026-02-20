//
//  ServiceProtocols.swift
//  TrainSwift
//
//  Protocol abstractions for key services to enable dependency injection and testing
//

import Foundation

// MARK: - Keychain Service Protocol

protocol KeychainServiceProtocol {
    func savePassword(_ password: String, for email: String) throws
    func verifyPassword(_ password: String, for email: String) -> Bool
    func updatePassword(_ newPassword: String, for email: String) throws
    func deletePassword(for email: String) throws

    func saveAppleUserIdentifier(_ identifier: String, for email: String) throws
    func retrieveAppleUserIdentifier(for email: String) throws -> String
    func deleteAppleUserIdentifier(for email: String) throws

    func saveGoogleUserIdentifier(_ identifier: String, for email: String) throws
    func retrieveGoogleUserIdentifier(for email: String) throws -> String
    func deleteGoogleUserIdentifier(for email: String) throws
}

// MARK: - Exercise Database Protocol

protocol ExerciseDatabaseProtocol {
    func fetchExercises(filter: ExerciseDatabaseFilter) throws -> [DBExercise]
    func fetchExercise(byId id: String) throws -> DBExercise?
    func fetchAlternatives(for exercise: DBExercise, filter: ExerciseDatabaseFilter) throws -> [DBExercise]
    func fetchContraindications(forExerciseId exerciseId: String) throws -> [String]
}

// MARK: - Conformance

extension KeychainService: KeychainServiceProtocol {}
extension ExerciseDatabaseManager: ExerciseDatabaseProtocol {}
