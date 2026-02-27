//
//  ExerciseDatabaseManager.swift
//  TrainSwift
//
//  Manages the SQLite exercise database using GRDB
//  Schema: exercises → equipment (via equipment_id_1/equipment_id_2 FKs)
//

import Foundation
import GRDB

class ExerciseDatabaseManager {
    static let shared = ExerciseDatabaseManager()

    private var dbQueue: DatabaseQueue?
    private let databaseFileName = "exercises.db"

    // Equipment cache — loaded once at startup, keyed by equipment_id
    // nonisolated(unsafe): written only during init, then read-only for the lifetime of the singleton
    private nonisolated(unsafe) var equipmentById: [String: DBEquipment] = [:]
    private nonisolated(unsafe) var equipmentByName: [String: DBEquipment] = [:]
    private nonisolated(unsafe) var equipmentByCategory: [String: [DBEquipment]] = [:]

    // Video GUID cache — loaded once at startup, keyed by exercise_id
    private nonisolated(unsafe) var videoGuidByExerciseId: [String: String] = [:]

    private init() {
        setupDatabase()
    }

    // MARK: - Equipment Cache

    /// Look up equipment by ID (used by DBExercise computed properties)
    func equipment(for id: String) -> DBEquipment? {
        return equipmentById[id]
    }

    /// Look up equipment by name (e.g., "Squat Rack")
    func equipmentByName(_ name: String) -> DBEquipment? {
        return equipmentByName[name]
    }

    /// Get all equipment in a category (e.g., "Barbells")
    func equipmentInCategory(_ category: String) -> [DBEquipment] {
        return equipmentByCategory[category] ?? []
    }

    /// Resolve user's questionnaire selections to a set of equipment IDs.
    /// - Parameters:
    ///   - categories: Equipment category names (e.g., ["Barbells", "Cables"])
    ///   - specificNames: Specific equipment names the user selected (e.g., ["Squat Rack", "Flat Bench Press"])
    ///   - attachmentNames: Attachment names the user selected (e.g., ["Rope", "Straight Bar"])
    /// - Returns: Set of equipment_id values the user has access to
    func resolveEquipmentIds(categories: [String], specificNames: [String], attachmentNames: [String]) -> Set<String> {
        var ids = Set<String>()

        for category in categories {
            // Add the "base" equipment for this category (where name == category, e.g., EP001 "Barbells/Barbells")
            if let items = equipmentByCategory[category] {
                for item in items where item.name == category {
                    ids.insert(item.equipmentId)
                }
            }
        }

        // Add IDs for selected specific equipment names
        for name in specificNames {
            if let equip = equipmentByName[name] {
                ids.insert(equip.equipmentId)
            }
        }

        // Add IDs for selected attachments
        for name in attachmentNames {
            if let equip = equipmentByName[name] {
                ids.insert(equip.equipmentId)
            }
        }

        // Also add "Other" category items that match any selected specific names
        // (e.g., "Flat Bench" is in Other, "Roman Chair" is in Other)
        if let otherItems = equipmentByCategory["Other"] {
            for item in otherItems where specificNames.contains(item.name) {
                ids.insert(item.equipmentId)
            }
        }

        return ids
    }

    private func loadEquipmentCache() {
        guard let dbQueue = dbQueue else { return }

        do {
            let allEquipment = try dbQueue.read { db in
                try DBEquipment.fetchAll(db)
            }

            equipmentById = Dictionary(uniqueKeysWithValues: allEquipment.map { ($0.equipmentId, $0) })
            equipmentByName = Dictionary(allEquipment.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })

            equipmentByCategory = [:]
            for item in allEquipment {
                equipmentByCategory[item.category, default: []].append(item)
            }

            AppLogger.logDatabase("Equipment cache loaded: \(allEquipment.count) items, \(equipmentByCategory.count) categories")
        } catch {
            AppLogger.logDatabase("Failed to load equipment cache: \(error)", level: .error)
        }
    }

    // MARK: - Video GUID Cache

    /// Look up Bunny Stream GUID for an exercise (O(1) dictionary lookup)
    func videoGuid(for exerciseId: String) -> String? {
        return videoGuidByExerciseId[exerciseId]
    }

    private func loadVideoGuidCache() {
        guard let dbQueue = dbQueue else { return }

        do {
            let allVideos = try dbQueue.read { db in
                try DBExerciseVideo.fetchAll(db)
            }

            videoGuidByExerciseId = Dictionary(uniqueKeysWithValues: allVideos.map { ($0.exerciseId, $0.bunnyGuid) })

            AppLogger.logDatabase("Video GUID cache loaded: \(videoGuidByExerciseId.count) entries")
        } catch {
            AppLogger.logDatabase("Failed to load video GUID cache: \(error)", level: .error)
        }
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

            // Load caches (must happen before any queries)
            loadEquipmentCache()
            loadVideoGuidCache()

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
            let equipmentCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM equipment") ?? 0
            let contraCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM exercise_contraindications") ?? 0
            let videoCount = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM exercise_videos") ?? 0

            AppLogger.logDatabase("Database verification: Exercises: \(exerciseCount), Equipment: \(equipmentCount), Contraindications: \(contraCount), Videos: \(videoCount)")

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

        // Resolve equipment IDs from filter
        let allowedIds: Set<String>
        if let preResolved = filter.allowedEquipmentIds {
            allowedIds = preResolved
        } else if !filter.equipmentCategories.isEmpty || !filter.equipmentSpecific.isEmpty || !filter.attachmentSpecific.isEmpty {
            allowedIds = resolveEquipmentIds(
                categories: filter.equipmentCategories,
                specificNames: filter.equipmentSpecific,
                attachmentNames: filter.attachmentSpecific
            )
        } else {
            allowedIds = [] // empty = no equipment filtering
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

            // Filter by equipment IDs
            // Exercise is available if:
            //   equipment_id_1 IN (user's IDs)
            //   AND (equipment_id_2 IS NULL OR equipment_id_2 IN (user's IDs))
            if !allowedIds.isEmpty {
                query = query.filter(
                    allowedIds.contains(Column("equipment_id_1")) &&
                    (Column("equipment_id_2") == nil || allowedIds.contains(Column("equipment_id_2")))
                )
            }

            // Filter by max complexity
            // DB stores "All" (capital A), "1", "2"
            switch filter.maxComplexity {
            case 1:
                // Beginners: include "All" and "1"
                query = query.filter(Column("complexity_level") == "All" || Column("complexity_level") == "1")
            default:
                // Intermediate+ / Advanced: include all complexity levels
                query = query.filter(Column("complexity_level") == "All" || Column("complexity_level") == "1" || Column("complexity_level") == "2")
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
        let placeholders = injuries.map { _ in "?" }.joined(separator: ",")
        let contraindicatedCanonicals = try String.fetchAll(
            db,
            sql: """
                SELECT DISTINCT canonical_name
                FROM exercise_contraindications
                WHERE injury_type IN (\(placeholders))
                """,
            arguments: StatementArguments(injuries)
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

    // MARK: - Contraindications

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

    func fetchContraindications(for exercise: DBExercise) throws -> [String] {
        return try fetchContraindications(forCanonicalName: exercise.canonicalName)
    }

    func isContraindicated(exercise: DBExercise, forInjuries injuries: [String]) throws -> Bool {
        guard !injuries.isEmpty else { return false }
        let contraindications = try fetchContraindications(for: exercise)
        return !Set(contraindications).isDisjoint(with: Set(injuries))
    }

    // MARK: - Metadata Queries

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

    /// Get all available equipment categories (from equipment table)
    func fetchAvailableEquipmentCategories() throws -> [String] {
        guard let dbQueue = dbQueue else {
            throw DatabaseError.databaseNotInitialized
        }

        return try dbQueue.read { db in
            try String.fetchAll(
                db,
                sql: """
                    SELECT DISTINCT eq.category
                    FROM equipment eq
                    INNER JOIN exercises ex ON ex.equipment_id_1 = eq.equipment_id
                    WHERE ex.is_in_programme = 1
                    ORDER BY eq.category
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
                    SELECT DISTINCT eq.name
                    FROM equipment eq
                    WHERE eq.category = ?
                      AND eq.name != ?
                    ORDER BY eq.name
                    """,
                arguments: [category, category]
            )
        }
    }

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
