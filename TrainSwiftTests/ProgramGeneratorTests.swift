//
//  ProgramGeneratorTests.swift
//  TrainSwiftTests
//
//  Unit tests for DynamicProgramGenerator rep ranges, rest seconds, and template logic
//

import XCTest
@testable import TrainSwift

final class ProgramGeneratorTests: XCTestCase {

    private var generator: DynamicProgramGenerator!

    override func setUp() {
        super.setUp()
        generator = DynamicProgramGenerator()
    }

    // MARK: - Rest Seconds from Rating

    func testHighRatingGives120sRest() {
        XCTAssertEqual(generator.getRestSecondsFromRating(90), 120)
        XCTAssertEqual(generator.getRestSecondsFromRating(81), 120)
        XCTAssertEqual(generator.getRestSecondsFromRating(100), 120)
    }

    func testMediumRatingGives90sRest() {
        XCTAssertEqual(generator.getRestSecondsFromRating(80), 90)
        XCTAssertEqual(generator.getRestSecondsFromRating(50), 90)
        XCTAssertEqual(generator.getRestSecondsFromRating(65), 90)
    }

    func testLowRatingGives60sRest() {
        XCTAssertEqual(generator.getRestSecondsFromRating(49), 60)
        XCTAssertEqual(generator.getRestSecondsFromRating(20), 60)
        XCTAssertEqual(generator.getRestSecondsFromRating(0), 60)
    }

    // MARK: - Rep Range for Goal and Rating

    func testGetStrongerOnlyHighRating() {
        // High rating (>75) with "get_stronger" only → should be "5-8" or "6-10"
        let range = generator.getRepRangeForGoalAndRating("get_stronger", canonicalRating: 80)
        XCTAssertTrue(["5-8", "6-10"].contains(range),
                       "Expected '5-8' or '6-10' but got '\(range)'")
    }

    func testGetStrongerOnlyLowRating() {
        // Low rating (≤75) with "get_stronger" only → should be "6-10" or "8-12"
        let range = generator.getRepRangeForGoalAndRating("get_stronger", canonicalRating: 50)
        XCTAssertTrue(["6-10", "8-12"].contains(range),
                       "Expected '6-10' or '8-12' but got '\(range)'")
    }

    func testIncreaseMuscleAndFatLoss() {
        // "increase_muscle" + "fat_loss" → should be "8-12" or "10-14"
        let range = generator.getRepRangeForGoalAndRating("increase_muscle,fat_loss", canonicalRating: 60)
        XCTAssertTrue(["8-12", "10-14"].contains(range),
                       "Expected '8-12' or '10-14' but got '\(range)'")
    }

    func testFatLossOnly() {
        // "fat_loss" only → should be "8-12" or "10-14"
        let range = generator.getRepRangeForGoalAndRating("fat_loss", canonicalRating: 50)
        XCTAssertTrue(["8-12", "10-14"].contains(range),
                       "Expected '8-12' or '10-14' but got '\(range)'")
    }

    func testIncreaseMuscleOnly() {
        // "increase_muscle" only → should be "6-10" or "8-12"
        let range = generator.getRepRangeForGoalAndRating("increase_muscle", canonicalRating: 50)
        XCTAssertTrue(["6-10", "8-12"].contains(range),
                       "Expected '6-10' or '8-12' but got '\(range)'")
    }

    func testDefaultGoalRepRange() {
        // Unknown goal → should default to "8-12"
        let range = generator.getRepRangeForGoalAndRating("unknown_goal", canonicalRating: 50)
        XCTAssertEqual(range, "8-12")
    }

    func testGetStrongerWithFatLoss() {
        // "get_stronger" + "fat_loss" → treated as strength-focused
        let range = generator.getRepRangeForGoalAndRating("get_stronger,fat_loss", canonicalRating: 80)
        XCTAssertTrue(["5-8", "6-10"].contains(range),
                       "Expected '5-8' or '6-10' but got '\(range)'")
    }

    // MARK: - Rep Range Consistency

    func testRepRangesAreAlwaysValid() {
        // Run multiple times since results are randomised
        let goals = ["get_stronger", "increase_muscle", "fat_loss",
                      "get_stronger,increase_muscle", "increase_muscle,fat_loss",
                      "get_stronger,fat_loss", "get_stronger,increase_muscle,fat_loss"]
        let ratings = [0, 25, 50, 75, 80, 100]
        let validRanges = Set(["5-8", "6-10", "8-12", "10-14"])

        for goal in goals {
            for rating in ratings {
                for _ in 0..<5 {
                    let range = generator.getRepRangeForGoalAndRating(goal, canonicalRating: rating)
                    XCTAssertTrue(validRanges.contains(range),
                                  "Invalid rep range '\(range)' for goal='\(goal)', rating=\(rating)")
                }
            }
        }
    }
}
