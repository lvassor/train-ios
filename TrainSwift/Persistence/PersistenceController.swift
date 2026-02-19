//
//  PersistenceController.swift
//  TrainSwift
//
//  Core Data persistence layer for workout data, user profiles, and programs
//

import CoreData
import Foundation

class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer
    private(set) var isUsingFallbackStore = false

    // MARK: - Initialization

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "TrainSwift")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { description, error in
            if let error = error {
                AppLogger.logDatabase("❌ Core Data failed to load: \(error.localizedDescription)", level: .fault)

                // Fallback to in-memory store instead of crashing
                self.isUsingFallbackStore = true
                self.setupFallbackStore()

                AppLogger.logDatabase("⚠️ Using in-memory fallback store - data will not persist", level: .warning)
            } else {
                print("✅ Core Data loaded successfully")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Fallback Store Setup

    private func setupFallbackStore() {
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                AppLogger.logDatabase("❌ Even fallback store failed: \(error)", level: .fault)
            } else {
                AppLogger.logDatabase("✅ Fallback in-memory store initialized", level: .warning)
            }
        }
    }

    // MARK: - Preview Helper

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        // Create sample data for previews
        let sampleUser = UserProfile(context: context)
        sampleUser.id = UUID()
        sampleUser.email = "preview@test.com"
        sampleUser.name = "Preview User"
        sampleUser.createdAt = Date()

        do {
            try context.save()
        } catch {
            print("❌ Preview data creation failed: \(error)")
        }

        return controller
    }()

    // MARK: - Save Context

    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
                print("✅ Core Data context saved")
            } catch {
                print("❌ Core Data save failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Delete All Data (for testing)

    func deleteAllData() {
        let entities = ["UserProfile", "WorkoutProgram", "WorkoutSession", "QuestionnaireResponse"]

        for entity in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try container.viewContext.execute(batchDeleteRequest)
                print("✅ Deleted all \(entity) records")
            } catch {
                print("❌ Failed to delete \(entity): \(error)")
            }
        }

        save()
    }
}
