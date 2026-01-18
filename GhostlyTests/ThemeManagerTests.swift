//
//  ThemeManagerTests.swift
//  GhostlyTests
//
//  Created by Ghostly Contributors
//

import XCTest
@testable import Ghostly

final class ThemeManagerTests: XCTestCase {

    override func setUpWithError() throws {
        UserDefaults.standard.removeObject(forKey: "theme")
    }

    override func tearDownWithError() throws {
        UserDefaults.standard.removeObject(forKey: "theme")
    }

    @MainActor func testDefaultTheme() throws {
        let themeManager = ThemeManager()
        XCTAssertEqual(themeManager.currentTheme, .system)
    }

    @MainActor func testSetThemeDark() throws {
        let themeManager = ThemeManager()
        themeManager.setTheme(.dark)
        XCTAssertEqual(themeManager.currentTheme, .dark)
    }

    @MainActor func testSetThemeLight() throws {
        let themeManager = ThemeManager()
        themeManager.setTheme(.light)
        XCTAssertEqual(themeManager.currentTheme, .light)
    }

    @MainActor func testSetThemeSystem() throws {
        let themeManager = ThemeManager()
        themeManager.setTheme(.dark)
        themeManager.setTheme(.system)
        XCTAssertEqual(themeManager.currentTheme, .system)
    }

    @MainActor func testThemePersistence() throws {
        // Set a theme
        let themeManager1 = ThemeManager()
        themeManager1.setTheme(.dark)

        // Create a new manager - should load persisted theme
        let themeManager2 = ThemeManager()
        XCTAssertEqual(themeManager2.currentTheme, .dark)
    }

    @MainActor func testThemeEditorVisibility() throws {
        let themeManager = ThemeManager()
        XCTAssertFalse(themeManager.isThemeEditor)

        themeManager.showThemeEditor()
        XCTAssertTrue(themeManager.isThemeEditor)

        themeManager.hideThemeEditor()
        XCTAssertFalse(themeManager.isThemeEditor)
    }

    @MainActor func testThemeRawValues() throws {
        XCTAssertEqual(Theme.system.rawValue, "system")
        XCTAssertEqual(Theme.light.rawValue, "light")
        XCTAssertEqual(Theme.dark.rawValue, "dark")
    }
}
