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

    @MainActor func testLaunchAtLoginPersistence() throws {
        // Set launch at login
        let settingsManager1 = SettingsManager()
        settingsManager1.launchAtLogin = true

        // Create a new manager - should load persisted setting
        let settingsManager2 = SettingsManager()
        XCTAssertTrue(settingsManager2.launchAtLogin)
    }
}
