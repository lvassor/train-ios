//
//  SpotlightIndexer.swift
//  TrainSwift
//
//  Indexes completed workouts in CoreSpotlight and registers Siri Shortcuts
//

import Foundation
import CoreSpotlight
import MobileCoreServices
import Intents

/// Indexes completed workouts in CoreSpotlight and registers Siri Shortcuts
class SpotlightIndexer {
    static let shared = SpotlightIndexer()

    private let domainIdentifier = "com.train.workouts"

    /// Index a completed workout session in Spotlight
    func indexWorkoutSession(id: UUID, sessionName: String, completedAt: Date, exerciseCount: Int, durationMinutes: Int) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
        attributeSet.title = sessionName
        attributeSet.contentDescription = "\(exerciseCount) exercises • \(durationMinutes) min"
        attributeSet.keywords = ["workout", "training", sessionName.lowercased(), "exercise"]

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        attributeSet.contentDescription = "\(sessionName) — \(dateFormatter.string(from: completedAt)) — \(exerciseCount) exercises"

        let item = CSSearchableItem(
            uniqueIdentifier: "workout-\(id.uuidString)",
            domainIdentifier: domainIdentifier,
            attributeSet: attributeSet
        )
        item.expirationDate = Calendar.current.date(byAdding: .month, value: 6, to: Date())

        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error = error {
                AppLogger.logUI("[SPOTLIGHT] Failed to index workout: \(error)", level: .error)
            } else {
                AppLogger.logUI("[SPOTLIGHT] Indexed workout: \(sessionName)")
            }
        }
    }

    /// Register "Start Workout" Siri Shortcut
    func registerStartWorkoutShortcut() {
        let activity = NSUserActivity(activityType: "com.train.startWorkout")
        activity.title = "Start my workout"
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.suggestedInvocationPhrase = "Start my workout"
        activity.persistentIdentifier = "com.train.startWorkout"

        let attributes = CSSearchableItemAttributeSet(contentType: .content)
        attributes.contentDescription = "Start your next training session in train."
        activity.contentAttributeSet = attributes

        // The activity needs to be "become current" to register
        activity.becomeCurrent()

        AppLogger.logUI("[SPOTLIGHT] Registered 'Start Workout' Siri Shortcut")
    }

    /// Remove all indexed workout items
    func removeAllIndexedItems() {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [domainIdentifier]) { error in
            if let error = error {
                AppLogger.logUI("[SPOTLIGHT] Failed to remove indexed items: \(error)", level: .error)
            }
        }
    }
}
