//
//  ColorPaletteTests.swift
//  TrainSwiftTests
//
//  Tests for ColorPalette theme colour consistency
//

import XCTest
import SwiftUI
@testable import TrainSwift

final class ColorPaletteTests: XCTestCase {

    // MARK: - All Themes Return Valid Hex

    func testPrimaryColorsReturnValidHex() {
        for theme in [ThemeVariant.gold, .orange, .light] {
            let hex = ColorPalette.primary(for: theme)
            XCTAssertTrue(hex.hasPrefix("#"), "Primary for \(theme) should start with #")
            XCTAssertEqual(hex.count, 7, "Primary hex for \(theme) should be 7 chars (#RRGGBB)")
        }
    }

    func testBackgroundColorsReturnValidHex() {
        for theme in [ThemeVariant.gold, .orange, .light] {
            let hex = ColorPalette.background(for: theme)
            XCTAssertTrue(hex.hasPrefix("#"), "Background for \(theme) should start with #")
        }
    }

    func testTextPrimaryColorsReturnValidHex() {
        for theme in [ThemeVariant.gold, .orange, .light] {
            let hex = ColorPalette.textPrimary(for: theme)
            XCTAssertTrue(hex.hasPrefix("#"), "Text primary for \(theme) should start with #")
        }
    }

    func testTextSecondaryColorsReturnValidHex() {
        for theme in [ThemeVariant.gold, .orange, .light] {
            let hex = ColorPalette.textSecondary(for: theme)
            XCTAssertTrue(hex.hasPrefix("#"), "Text secondary for \(theme) should start with #")
        }
    }

    // MARK: - Theme Differentiation

    func testDarkAndLightBackgroundsDiffer() {
        let darkBg = ColorPalette.background(for: .orange)
        let lightBg = ColorPalette.background(for: .light)
        XCTAssertNotEqual(darkBg, lightBg,
                           "Dark and light backgrounds should differ")
    }

    func testDarkAndLightTextPrimaryDiffer() {
        let darkText = ColorPalette.textPrimary(for: .orange)
        let lightText = ColorPalette.textPrimary(for: .light)
        XCTAssertNotEqual(darkText, lightText,
                           "Dark and light text primary should differ")
    }

    // MARK: - Gold and Orange Share Some Values

    func testGoldAndOrangeShareBackgrounds() {
        // Gold and Orange dark modes share the same background
        XCTAssertEqual(
            ColorPalette.background(for: .gold),
            ColorPalette.background(for: .orange),
            "Gold and orange should share the same dark background"
        )
    }

    // MARK: - Gradient Colors Complete

    func testGradientColorsExist() {
        for theme in [ThemeVariant.gold, .orange, .light] {
            let light = ColorPalette.gradientLight(for: theme)
            let mid = ColorPalette.gradientMid(for: theme)
            let dark = ColorPalette.gradientDark(for: theme)

            XCTAssertTrue(light.hasPrefix("#"), "Gradient light for \(theme)")
            XCTAssertTrue(mid.hasPrefix("#"), "Gradient mid for \(theme)")
            XCTAssertTrue(dark.hasPrefix("#"), "Gradient dark for \(theme)")
        }
    }

    // MARK: - Semantic Colors Exist

    func testSemanticColorsExist() {
        // These are static lets, just verify they're accessible
        _ = Color.trainSuccess
        _ = Color.trainWarning
        _ = Color.trainError
        _ = Color.trainInfo
        _ = Color.trainPlaceholder
        _ = Color.trainTag
        _ = Color.trainTabBackground
    }

    // MARK: - Border Colors

    func testBorderColorsReturnValidHex() {
        for theme in [ThemeVariant.gold, .orange, .light] {
            let subtle = ColorPalette.borderSubtle(for: theme)
            let defaultBorder = ColorPalette.borderDefault(for: theme)
            let strong = ColorPalette.borderStrong(for: theme)

            XCTAssertTrue(subtle.hasPrefix("#"))
            XCTAssertTrue(defaultBorder.hasPrefix("#"))
            XCTAssertTrue(strong.hasPrefix("#"))
        }
    }
}
