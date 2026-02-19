//
//  ExerciseDatabaseManager.swift
//  TrainSwift
//
//  Manages the SQLite exercise database using GRDB
//  Updated for new schema with equipment_category/equipment_specific hierarchy
//

import Foundation
import GRDB

class ExerciseDatabaseManager {
    static let shared = ExerciseDatabaseManager()

    private var dbQueue: DatabaseQueue?
    private let databaseFileName = "exercises.db"

    private init() {
        setupDatabase()
    }

    // MARK: - Database Setup

    private func setupDatabase() {
        do {
            let fileManager = FileManager.default
            let documentsPath = try fileManager.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let databaseURL = documentsPath.appendingPathComponent(databaseFileName)

            // Always copy database from bundle to ensure we have latest version
            // This ensures updates to the database are propagated
            if let bundleURL = Bundle.main.url(forResource: "exercises", withExtension: "db") {
                let bundleModified = try fileManager.attributesOfItem(atPath: bundleURL.path)[.modificationDate] as? Date ?? Date.distantPast

                var shouldCopy = !fileManager.fileExists(atPath: databaseURL.path)

                if fileManager.fileExists(atPath: databaseURL.path) {
                    let docModified = try fileManager.attributesOfItem(atPath: databaseURL.path)[.modificationDate] as? Date ?? Date.distantPast
                    shouldCopy = bundleModified > docModified
                }

                if shouldCopy {
                    AppLogger.logDatabase("Copying updated database from bundle...")
                    if fileManager.fileExists(atPath: databaseURL.path) {
                        try fileManager.removeItem(at: databaseURL)
                    }
                    try fileManager.copyItem(at: bundleURL, to: databaseURL)
                    AppLogger.logDatabase("Database updated from bundle")
                }
            } else if !fileManager.fileExists(atPath: databaseURL.path) {
                throw DatabaseError.bundleDatabaseNotFound
            }

            // Open database connection
            dbQueue = try DatabaseQueue(path: databaseURL.path)
            AppLogger.logDatabase("Exercise database initialized at: \(databaseURL.path)")

            // Verify database integrity
            try verifyDatabase()

        } catch {
            AppLogger.logDatabase("Failed to setup database: \(error.localizedDescription)", level: .error)
        }
    }

    private func verifyDatabase() throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.databaseNotInitialized
        }

        try dbQueue.read { db in
            let exerciseCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM exercises") ?? 0
            let contraCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM exercise_contraindications") ?? 0

            AppLogger.logDatabase("Database verification: Exercises: \(exerciseCount), Contraindications: \(contraCount)")

            if exerciseCount == 0 {
                throw DatabaseError.emptyDatabase
            }
        }
    }

    // MARK: - Query Methods

    /// Fetch all exercises matching the filter criteria
    func fetchExercises(filter: ExerciseDatabaseFilter) throws -> [DBExercise] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.databaseNotInitialized
        }

        return try dbQueue.read { db in
            var query = DBExercise.all()

            // Filter by programme inclusion
            if filter.onlyProgrammeExercises {
                query = query.filter(Column("is_in_programme") == 1)
            }

            // Filter by canonical name (movement pattern for exercise swaps)
            if let canonical = filter.canonicalName {
                query = query.filter(Column("canonical_name") == canonical)
            }

            // Filter by primary muscle
            if let muscle = filter.primaryMuscle {
                query = query.filter(Column("primary_muscle") == muscle)
            }

            // Filter by equipment categories (Barbells, Dumbbells, Cables, etc.)
            if !filter.equipmentCategories.isEmpty {
                query = query.filter(filter.equipmentCategories.contains(Column("equipment_category")))
            }

            // Filter by specific equipment (Squat Rack, Flat Bench, etc.)
            if !filter.equipmentSpecific.isEmpty {
                // Include exercises where equipment_specific is in the list OR equipment_specific is NULL
                query = query.filter(
                    filter.equipmentSpecific.contains(Column("equipment_specific")) ||
                    Column("equipment_specific") == nil
                )
            }

            // Filter by attachments (Rope, D-Handles, Straight Bar, etc.)
            if !filter.attachmentSpecific.isEmpty {
                // Include exercises where attachment_specific is in the list OR attachment_specific is NULL
                // Exercises without attachments always pass through
                query = query.filter(
                    filter.attachmentSpecific.contains(Column("attachment_specific")) ||
                    Column("attachment_specific") == nil
                )
            }

            // Filter by max complexity
            // NOTE: complexity_level is stored as TEXT ("all", "1", "2") not INT
            // "all" = available to everyone (numeric value 0)
            // "1" = beginner only (numeric value 1)
            // "2" = intermediate+ (numeric value 2)
            // We must use string comparison, not numeric comparison
            switch filter.maxComplexity {
            case 1:
                // Beginners: include "all" and "1"
                query = query.filter(Column("complexity_level") == "all" || Column("complexity_level") == "1")
            case 2:
                // Intermediate+: include "all", "1", and "2"
                query = query.filter(Column("complexity_level") == "all" || Column("complexity_level") == "1" || Column("complexity_level") == "2")
            default:
                // Advanced or no filter: include all complexity levels
                query = query.filter(Column("complexity_level") == "all" || Column("complexity_level") == "1" || Column("complexity_level") == "2")
            }

            // Fetch matching exercises
            var exercises = try query.fetchAll(db)

            // Filter out contraindicated exercises (requires separate query)
            if !filter.excludeInjuries.isEmpty {
                exercises = try filterContraindicatedExercises(
                    exercises,
                    excludingInjuries: filter.excludeInjuries,
                    in: db
                )
            }

            // Filter out excluded exercise IDs
            if !filter.excludeExerciseIds.isEmpty {
                exercises = exercises.filter { !filter.excludeExerciseIds.contains($0.exerciseId) }
            }

            // Order by complexity (descending) for better exercise selection
            exercises.sort { $0.numericComplexity > $1.numericComplexity }

            return exercises
        }
    }

    /// Filter out exercises that are contraindicated for the given injuries
    private func filterContraindicatedExercises(
        _ exercises: [DBExercise],
        excludingInjuries injuries: [String],
        in db: Database
    ) throws -> [DBExercise] {
        // Get all contraindicated canonical names for the given injuries
        let contraindicatedCanonicals = try String.fetchAll(
            db,
            sql: """
                SELECT DISTINCT canonical_name
                FROM exercise_contraindications
                WHERE injury_type IN (\(injuries.map { "'\($0)'" }.joined(separator: ",")))
                """
        )

        let contraindicatedSet = Set(contraindicatedCanonicals)
        return exercises.filter { !contraindicatedSet.contains($0.canonicalName) }
    }

    /// Fetch a single exercise by ID
    func fetchExercise(byId id: String) throws -> DBExercise? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.databaseNotInitialized
        }

        return try dbQueue.read { db in
            try DBExercise
                .filter(Column("exercise_id") == id)
                .fetchOne(db)
        }
    }

    /// Get all contraindications for a specific exercise (by canonical name)
    func fetchContraindications(forCanonicalName canonicalName: String) throws -> [String] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.databaseNotInitialized
        }

        return try dbQueue.read { db in
            try String.fetchAll(
                db,
                sql: """
                    SELECT injury_type
                    FROM exercise_contraindications
                    WHERE canonical_name = ?
                    ORDER BY injury_type
                    """,
                arguments: [canonicalName]
            )
        }
    }

    /// Get all contraindications for a specific exercise (by exercise)
    func fetchContraindications(for exercise: DBExercise) throws -> [String] {
        return try fetchContraindications(forCanonicalName: exercise.canonicalName)
    }

    /// Check if an exercise is contraindicated for a given set of injuries
    func isContraindicated(exercise: DBExercise, forInjuries injuries: [String]) throws -> Bool {
        guard !injuries.isEmpty else { return false }

        let contraindications = try fetchContraindications(for: exercise)
        return !Set(contraindications).isDisjoint(with: Set(injuries))
    }

    /// Get all available canonical names (movement patterns)
    func fetchAvailableCanonicalNames() throws -> [String] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.databaseNotInitialized
        }

        return try dbQueue.read { db in
            try String.fetchAll(
                db,
                sql: """
                    SELECT DISTINCT canonical_name
                    FROM exercises
                    WHERE is_in_programme = 1
                    ORDER BY canonical_name
                    """
            )
        }
    }

    /// Get all available equipment categories
    func fetchAvailableEquipmentCategories() throws -> [String] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.databaseNotInitialized
        }

        return try dbQueue.read { db in
            try String.fetchAll(
                db,
                sql: """
                    SELECT DISTINCT equipment_category
                    FROM exercises
                    WHERE is_in_programme = 1
                    ORDER BY equipment_category
                    """
            )
        }
    }

    /// Get all available specific equipment for a given category
    func fetchAvailableEquipmentSpecific(forCategory category: String) throws -> [String] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.databaseNotInitialized
        }

        return try dbQueue.read { db in
            try String.fetchAll(
                db,
                sql: """
                    SELECT DISTINCT equipment_specific
                    FROM exercises
                    WHERE is_in_programme = 1
                      AND equipment_category = ?
                      AND equipment_specific IS NOT NULL
                    ORDER BY equipment_specific
                    """,
                arguments: [category]
            )
        }
    }

    /// Get all available muscles
    func fetchAvailableMuscles() throws -> [String] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.databaseNotInitialized
        }

        return try dbQueue.read { db in
            try String.fetchAll(
                db,
                sql: """
                    SELECT DISTINCT primary_muscle
                    FROM exercises
                    WHERE is_in_programme = 1
                    ORDER BY primary_muscle
                    """
            )
        }
    }

    /// Get all available injury types
    func fetchAvailableInjuryTypes() throws -> [String] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.databaseNotInitialized
        }

        return try dbQueue.read { db in
            try String.fetchAll(
                db,
                sql: """
                    SELECT DISTINCT injury_type
                    FROM exercise_contraindications
                    ORDER BY injury_type
                    """
            )
        }
    }

    /// Get alternative exercises (same canonical name, different ID)
    func fetchAlternatives(for exercise: DBExercise, filter: ExerciseDatabaseFilter) throws -> [DBExercise] {
        var alternativeFilter = filter
        alternativeFilter.canonicalName = exercise.canonicalName
        alternativeFilter.excludeExerciseIds.insert(exercise.exerciseId)

        return try fetchExercises(filter: alternativeFilter)
    }

    // MARK: - Legacy compatibility methods

    /// Legacy method - now returns equipment categories
    func fetchAvailableEquipmentNames() throws -> [String] {
        return try fetchAvailableEquipmentCategories()
    }

    /// Legacy method - no longer applicable, returns empty
    func fetchAvailableEquipmentTypes() throws -> [String] {
        return []
    }

    /// Legacy method - use fetchContraindications(for:) instead
    func fetchContraindications(forExerciseId exerciseId: String) throws -> [String] {
        guard let exercise = try fetchExercise(byId: exerciseId) else {
            return []
        }
        return try fetchContraindications(for: exercise)
    }
}

// MARK: - Database Errors

enum DatabaseError: LocalizedError {
    case bundleDatabaseNotFound
    case databaseNotInitialized
    case emptyDatabase

    var errorDescription: String? {
        switch self {
        case .bundleDatabaseNotFound:
            return "exercises.db not found in app bundle. Make sure it's added to Resources."
        case .databaseNotInitialized:
            return "Database has not been initialized."
        case .emptyDatabase:
            return "Database is empty or corrupted."
        }
    }
}
