//
//  EquipmentFilterTests.swift
//  TrainSwiftTests
//
//  Tests for the normalised equipment filter logic.
//  These tests validate the 2-FK equipment filter at the SQL level against exercises.db.
//  Once Swift models are updated (Phase 13d+), these can be refactored to use
//  ExerciseDatabaseManager directly.
//

import XCTest
import GRDB
@testable import TrainSwift

final class EquipmentFilterTests: XCTestCase {

    private var dbQueue: DatabaseQueue!

    override func setUp() {
        super.setUp()
        // Load exercises.db from the app bundle
        guard let dbPath = Bundle.main.path(forResource: "exercises", ofType: "db") else {
            XCTFail("exercises.db not found in bundle")
            return
        }
        do {
            dbQueue = try DatabaseQueue(path: dbPath)
        } catch {
            XCTFail("Failed to open exercises.db: \(error)")
        }
    }

    // MARK: - Schema Validation

    func testEquipmentTableExists() throws {
        try dbQueue.read { db in
            let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM equipment")
            XCTAssertEqual(count, 61, "Equipment table should have 61 entries")
        }
    }

    func testExercisesHaveEquipmentFKColumns() throws {
        try dbQueue.read { db in
            // Verify equipment_id_1 and equipment_id_2 columns exist
            let row = try Row.fetchOne(db, sql: """
                SELECT exercise_id, equipment_id_1, equipment_id_2
                FROM exercises LIMIT 1
            """)
            XCTAssertNotNil(row, "Should be able to query equipment FK columns")
        }
    }

    func testAllEquipmentFKsAreValid() throws {
        try dbQueue.read { db in
            // No exercise should reference a non-existent equipment_id
            let badFK1 = try Int.fetchOne(db, sql: """
                SELECT COUNT(*) FROM exercises
                WHERE equipment_id_1 NOT IN (SELECT equipment_id FROM equipment)
            """)
            XCTAssertEqual(badFK1, 0, "All equipment_id_1 values should exist in equipment table")

            let badFK2 = try Int.fetchOne(db, sql: """
                SELECT COUNT(*) FROM exercises
                WHERE equipment_id_2 IS NOT NULL
                AND equipment_id_2 NOT IN (SELECT equipment_id FROM equipment)
            """)
            XCTAssertEqual(badFK2, 0, "All equipment_id_2 values should exist in equipment table")
        }
    }

    // MARK: - Equipment Filter Logic (SQL-level)

    /// Helper: run the 2-FK equipment filter and return matching exercise IDs
    private func filteredExerciseIds(userEquipmentIds: Set<String>) throws -> Set<String> {
        var result = Set<String>()
        try dbQueue.read { db in
            let placeholders = userEquipmentIds.map { _ in "?" }.joined(separator: ", ")
            let sql = """
                SELECT exercise_id FROM exercises
                WHERE equipment_id_1 IN (\(placeholders))
                AND (equipment_id_2 IS NULL OR equipment_id_2 IN (\(placeholders)))
                AND is_in_programme = 1
            """
            // Arguments: user IDs for id_1 filter + user IDs for id_2 filter
            let args = Array(userEquipmentIds) + Array(userEquipmentIds)
            let rows = try String.fetchAll(db, sql: sql, arguments: StatementArguments(args))
            result = Set(rows)
        }
        return result
    }

    func testBasicInclusion_BarbellsOnly() throws {
        // User has only Barbells (EP001) — should get barbell-only exercises
        let userSet: Set<String> = ["EP001", "EP043"]  // Barbells + Bodyweight (always included)
        let results = try filteredExerciseIds(userEquipmentIds: userSet)

        // Barbell Curl (EX004) has equipment_id_1=EP001, equipment_id_2=NULL → should be included
        XCTAssertTrue(results.contains("EX004"), "Barbell Curl should be included (EP001, NULL)")
    }

    func testExcludesUnownedEquipment() throws {
        // User has Barbells (EP001) but NOT Flat Bench Press (EP003)
        let userSet: Set<String> = ["EP001", "EP043"]
        let results = try filteredExerciseIds(userEquipmentIds: userSet)

        // Barbell Bench Press (EX022) has equipment_id_1=EP001, equipment_id_2=EP003 → should be EXCLUDED
        XCTAssertFalse(results.contains("EX022"), "Barbell Bench Press should be excluded (user lacks EP003)")
    }

    func testNullableId2AlwaysMatches() throws {
        // Exercises with equipment_id_2 = NULL should match any user who has equipment_id_1
        let userSet: Set<String> = ["EP001", "EP043"]
        let results = try filteredExerciseIds(userEquipmentIds: userSet)

        // Count exercises with EP001 as id_1 and NULL id_2
        try dbQueue.read { db in
            let nullId2Exercises = try String.fetchAll(db, sql: """
                SELECT exercise_id FROM exercises
                WHERE equipment_id_1 = 'EP001'
                AND equipment_id_2 IS NULL
                AND is_in_programme = 1
            """)
            for exId in nullId2Exercises {
                XCTAssertTrue(results.contains(exId), "\(exId) should be included (EP001, NULL)")
            }
        }
    }

    func testPinLoadedPlateLoadedDistinct() throws {
        // User with pin-loaded leg press (EP017) but NOT plate-loaded (EP031)
        let userSet: Set<String> = ["EP017", "EP043"]
        let results = try filteredExerciseIds(userEquipmentIds: userSet)

        // Pin-loaded leg press exercise (EX073) should be included
        // Plate-loaded leg press exercise (EX074) should be excluded
        try dbQueue.read { db in
            // Find exercises with EP017 as id_1
            let pinLoadedExercises = try String.fetchAll(db, sql: """
                SELECT exercise_id FROM exercises
                WHERE equipment_id_1 = 'EP017'
                AND is_in_programme = 1
            """)
            for exId in pinLoadedExercises {
                XCTAssertTrue(results.contains(exId), "Pin-loaded exercise \(exId) should be included")
            }

            // Find exercises with EP031 as id_1
            let plateLoadedExercises = try String.fetchAll(db, sql: """
                SELECT exercise_id FROM exercises
                WHERE equipment_id_1 = 'EP031'
                AND is_in_programme = 1
            """)
            for exId in plateLoadedExercises {
                XCTAssertFalse(results.contains(exId), "Plate-loaded exercise \(exId) should be excluded")
            }
        }
    }

    func testBodyweightExercisesIncluded() throws {
        // Bodyweight (EP043) should always be in user's set
        let userSet: Set<String> = ["EP043"]
        let results = try filteredExerciseIds(userEquipmentIds: userSet)

        // Should have bodyweight-only exercises (EP043, NULL)
        XCTAssertGreaterThan(results.count, 0, "Should have bodyweight exercises")

        try dbQueue.read { db in
            let bwExercises = try String.fetchAll(db, sql: """
                SELECT exercise_id FROM exercises
                WHERE equipment_id_1 = 'EP043'
                AND equipment_id_2 IS NULL
                AND is_in_programme = 1
            """)
            for exId in bwExercises {
                XCTAssertTrue(results.contains(exId), "Bodyweight exercise \(exId) should be included")
            }
        }
    }

    func testCableWithAttachment() throws {
        // User with Single Adjustable Cable (EP013) + Rope (EP052) should get cable rope exercises
        let userSetWithRope: Set<String> = ["EP013", "EP052", "EP043"]
        let resultsWithRope = try filteredExerciseIds(userEquipmentIds: userSetWithRope)

        // User with cable machine but WITHOUT Rope should NOT get cable rope exercises
        let userSetNoRope: Set<String> = ["EP013", "EP043"]
        let resultsNoRope = try filteredExerciseIds(userEquipmentIds: userSetNoRope)

        // Find exercises that need EP013 + EP052
        try dbQueue.read { db in
            let cableRopeExercises = try String.fetchAll(db, sql: """
                SELECT exercise_id FROM exercises
                WHERE equipment_id_1 = 'EP013'
                AND equipment_id_2 = 'EP052'
                AND is_in_programme = 1
            """)

            for exId in cableRopeExercises {
                XCTAssertTrue(resultsWithRope.contains(exId), "\(exId) should be included with rope")
                XCTAssertFalse(resultsNoRope.contains(exId), "\(exId) should be excluded without rope")
            }
        }
    }

    func testFullGymUserGetsAllProgrammeExercises() throws {
        // A user with ALL equipment should get every is_in_programme=1 exercise
        try dbQueue.read { db in
            let allEquipmentIds = try String.fetchAll(db, sql: "SELECT equipment_id FROM equipment")
            let userSet = Set(allEquipmentIds)
            let results = try filteredExerciseIds(userEquipmentIds: userSet)

            let totalProgramme = try Int.fetchOne(db, sql: """
                SELECT COUNT(*) FROM exercises WHERE is_in_programme = 1
            """)
            XCTAssertEqual(results.count, totalProgramme, "Full gym user should get all programme exercises")
        }
    }

    // MARK: - Auto-Include Rule (app-level logic)

    func testAutoIncludeCategories() {
        // When user selects Squat Rack (EP002), the app should auto-add EP001 (Barbells)
        // This tests the SET CONSTRUCTION logic, not the SQL filter

        var selectedIds: Set<String> = ["EP002"]  // User ticked Squat Rack

        // Auto-include rule: if any Barbells child is selected, add EP001
        // Barbells children: EP002-EP009 (Squat Rack, Flat Bench, Incline Bench, etc.)
        let barbellsChildren: Set<String> = ["EP002", "EP003", "EP004", "EP005", "EP006", "EP007", "EP008", "EP009"]
        if !barbellsChildren.isDisjoint(with: selectedIds) {
            selectedIds.insert("EP001")  // Add Barbells self-ref
        }

        // Bodyweight always included
        selectedIds.insert("EP043")

        XCTAssertTrue(selectedIds.contains("EP001"), "EP001 (Barbells) should be auto-included when any barbell child is selected")
        XCTAssertTrue(selectedIds.contains("EP043"), "EP043 (Bodyweight) should always be included")
    }
}
