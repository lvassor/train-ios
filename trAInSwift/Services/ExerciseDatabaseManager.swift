//
//  ExerciseDatabaseManager.swift
//  trAInSwift
//
//  Manages the SQLite exercise database using GRDB
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

            // Check if database exists in Documents directory
            if !fileManager.fileExists(atPath: databaseURL.path) {
                print("📦 Database not found in Documents. Copying from bundle...")
                try copyDatabaseFromBundle(to: databaseURL)
            }

            // Open database connection
            dbQueue = try DatabaseQueue(path: databaseURL.path)
            print("✅ Exercise database initialized at: \(databaseURL.path)")

            // Verify database integrity
            try verifyDatabase()

        } catch {
            print("❌ Failed to setup database: \(error.localizedDescription)")
        }
    }

    private func copyDatabaseFromBundle(to destinationURL: URL) throws {
        guard let bundleURL = Bundle.main.url(forResource: "exercises", withExtension: "db") else {
            throw DatabaseError.bundleDatabaseNotFound
        }

        try FileManager.default.copyItem(at: bundleURL, to: destinationURL)
        print("✅ Database copied from bundle to Documents directory")
    }

    private func verifyDatabase() throws {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.databaseNotInitialized
        }

        try dbQueue.read { db in
            let exerciseCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM exercises") ?? 0
            let contraCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM exercise_contraindications") ?? 0
            let expCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM user_experience_complexity") ?? 0

            print("📊 Database verification:")
            print("   - Exercises: \(exerciseCount)")
            print("   - Contraindications: \(contraCount)")
            print("   - Experience levels: \(expCount)")

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

            // Filter by active status
            if filter.requireActive {
                query = query.filter(Column("is_active") == 1)
            }

            // Filter by movement pattern
            if let pattern = filter.movementPattern {
                query = query.filter(Column("movement_pattern") == pattern)
            }

            // Filter by primary muscle
            if let muscle = filter.primaryMuscle {
                query = query.filter(Column("primary_muscle") == muscle)
            }

            // Filter by complexity level
            query = query.filter(Column("complexity_level") <= filter.maxComplexity)

            // Filter by equipment types
            if !filter.equipmentTypes.isEmpty {
                query = query.filter(filter.equipmentTypes.contains(Column("equipment_type")))
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
            exercises.sort { $0.complexityLevel > $1.complexityLevel }

            return exercises
        }
    }

    /// Filter out exercises that are contraindicated for the given injuries
    private func filterContraindicatedExercises(
        _ exercises: [DBExercise],
        excludingInjuries injuries: [String],
        in db: Database
    ) throws -> [DBExercise] {
        // Get all contraindicated exercise IDs for the given injuries
        let contraindicatedIds = try Int.fetchAll(
            db,
            sql: """
                SELECT DISTINCT exercise_id
                FROM exercise_contraindications
                WHERE injury_type IN (\(injuries.map { "'\($0)'" }.joined(separator: ",")))
                """
        )

        let contraindicatedSet = Set(contraindicatedIds)
        return exercises.filter { !contraindicatedSet.contains($0.exerciseId) }
    }

    /// Fetch a single exercise by ID
    func fetchExercise(byId id: Int) throws -> DBExercise? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.databaseNotInitialized
        }

        return try dbQueue.read { db in
            try DBExercise
                .filter(Column("exercise_id") == id)
                .fetchOne(db)
        }
    }

    /// Fetch experience complexity rules for a given experience level
    func fetchExperienceComplexity(for level: ExperienceLevel) throws -> DBUserExperienceComplexity? {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.databaseNotInitialized
        }

        return try dbQueue.read { db in
            try DBUserExperienceComplexity
                .filter(Column("experience_level") == level.rawValue)
                .fetchOne(db)
        }
    }

    /// Get all contraindications for a specific exercise
    func fetchContraindications(forExerciseId exerciseId: Int) throws -> [String] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.databaseNotInitialized
        }

        return try dbQueue.read { db in
            try String.fetchAll(
                db,
                sql: """
                    SELECT injury_type
                    FROM exercise_contraindications
                    WHERE exercise_id = ?
                    ORDER BY injury_type
                    """,
                arguments: [exerciseId]
            )
        }
    }

    /// Get all available movement patterns
    func fetchAvailableMovementPatterns() throws -> [String] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.databaseNotInitialized
        }

        return try dbQueue.read { db in
            try String.fetchAll(
                db,
                sql: """
                    SELECT DISTINCT movement_pattern
                    FROM exercises
                    WHERE is_active = 1
                    ORDER BY movement_pattern
                    """
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
                    WHERE is_active = 1
                    ORDER BY primary_muscle
                    """
            )
        }
    }

    /// Get alternative exercises (same movement pattern, different ID)
    func fetchAlternatives(for exercise: DBExercise, filter: ExerciseDatabaseFilter) throws -> [DBExercise] {
        var alternativeFilter = filter
        alternativeFilter.movementPattern = exercise.movementPattern
        alternativeFilter.excludeExerciseIds.insert(exercise.exerciseId)

        return try fetchExercises(filter: alternativeFilter)
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
