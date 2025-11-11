//
//  UserProfile+Extensions.swift
//  trAInSwift
//
//  Core Data entity extensions for UserProfile
//

import CoreData
import Foundation

extension UserProfile {

    // MARK: - Fetch Methods

    static func fetch(byEmail email: String, context: NSManagedObjectContext) -> UserProfile? {
        let request = UserProfile.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@", email.lowercased())
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("❌ Failed to fetch user by email: \(error)")
            return nil
        }
    }

    static func fetch(byId id: UUID, context: NSManagedObjectContext) -> UserProfile? {
        let request = UserProfile.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("❌ Failed to fetch user by ID: \(error)")
            return nil
        }
    }

    static func fetchAll(context: NSManagedObjectContext) -> [UserProfile] {
        let request = UserProfile.fetchRequest()

        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch all users: \(error)")
            return []
        }
    }

    // MARK: - Create Method

    static func create(email: String, context: NSManagedObjectContext) -> UserProfile {
        let user = UserProfile(context: context)
        user.id = UUID()
        user.email = email.lowercased()
        user.createdAt = Date()
        user.lastLoginAt = Date()
        return user
    }

    // MARK: - Helper Methods

    func updateLastLogin() {
        self.lastLoginAt = Date()
    }

    // MARK: - Array Helpers

    var equipmentArray: [String] {
        get { equipment ?? [] }
        set { equipment = newValue }
    }

    var injuriesArray: [String] {
        get { injuries ?? [] }
        set { injuries = newValue }
    }

    var healedInjuriesArray: [String] {
        get { healedInjuries ?? [] }
        set { healedInjuries = newValue }
    }

    var priorityMusclesArray: [String] {
        get { priorityMuscles ?? [] }
        set { priorityMuscles = newValue }
    }

    // MARK: - Questionnaire Data Helpers

    func setQuestionnaireData(_ data: QuestionnaireData) {
        if let encoded = try? JSONEncoder().encode(data) {
            self.questionnaireData = encoded
        }
    }

    func getQuestionnaireData() -> QuestionnaireData? {
        guard let data = questionnaireData else { return nil }
        return try? JSONDecoder().decode(QuestionnaireData.self, from: data)
    }
}
