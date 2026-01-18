//
//  SettingsManagerTests.swift
//  GhostlyTests
//
//  Created by Ghostly Contributors
//

import XCTest
@testable import Ghostly

final class SettingsManagerTests: XCTestCase {

    override func setUpWithError() throws {
        UserDefaults.standard.removeObject(forKey: "launchAtLogin")
    }

    override func tearDownWithError() throws {
        UserDefaults.standard.removeObject(forKey: "launchAtLogin")
    }

    @MainActor func testDefaultLaunchAtLogin() throws {
        let settingsManager = SettingsManager()
        XCTAssertFalse(settingsManager.launchAtLogin)
    }

    @MainActor func testSettingsVisibility() throws {
        let settingsManager = SettingsManager()
        XCTAssertFalse(settingsManager.isSettingsOpen)

        settingsManager.showSettings()
        XCTAssertTrue(settingsManager.isSettingsOpen)

        settingsManager.hideSettings()
        XCTAssertFalse(settingsManager.isSettingsOpen)
    }

    @MainActor func testLaunchAtLoginToggle() throws {
        // Test that toggling launchAtLogin updates UserDefaults
        let settingsManager = SettingsManager()
        let initialState = settingsManager.launchAtLogin

        // Toggle the setting
        settingsManager.launchAtLogin = !initialState

        // Verify UserDefaults is updated
        XCTAssertEqual(UserDefaults.standard.bool(forKey: "launchAtLogin"), !initialState)

        // Toggle back
        settingsManager.launchAtLogin = initialState
        XCTAssertEqual(UserDefaults.standard.bool(forKey: "launchAtLogin"), initialState)
    }
}
