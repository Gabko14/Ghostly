//
//  SettingsManagerTests.swift
//  GhostlyTests
//
//  Created by Ghostly Contributors
//

import Foundation
import Testing
@testable import Ghostly

@Suite("SettingsManager Tests")
@MainActor
struct SettingsManagerTests {

    @Test("Default launch at login is based on SMAppService status")
    func defaultLaunchAtLoginBasedOnSMAppService() {
        let settingsManager = SettingsManager()
        // The initial state depends on actual system settings, so we just verify
        // that the property is readable and returns a boolean
        _ = settingsManager.launchAtLogin
    }

    @Test("Settings initially closed")
    func settingsInitiallyClosed() {
        let settingsManager = SettingsManager()
        #expect(settingsManager.isSettingsOpen == false)
    }

    @Test("Show settings sets state to true")
    func showSettingsSetsTrue() {
        let settingsManager = SettingsManager()
        settingsManager.showSettings()
        #expect(settingsManager.isSettingsOpen == true)
    }

    @Test("Hide settings sets state to false")
    func hideSettingsSetsFalse() {
        let settingsManager = SettingsManager()
        settingsManager.showSettings()
        #expect(settingsManager.isSettingsOpen == true)

        settingsManager.hideSettings()
        #expect(settingsManager.isSettingsOpen == false)
    }

    @Test("Toggle settings flips state")
    func toggleSettingsFlipsState() {
        let settingsManager = SettingsManager()
        #expect(settingsManager.isSettingsOpen == false)

        settingsManager.toggleSettings()
        #expect(settingsManager.isSettingsOpen == true)

        settingsManager.toggleSettings()
        #expect(settingsManager.isSettingsOpen == false)
    }

    @Test("Multiple toggles cycle correctly")
    func multipleTogglesCycle() {
        let settingsManager = SettingsManager()

        for _ in 0..<5 {
            settingsManager.toggleSettings()
            #expect(settingsManager.isSettingsOpen == true)
            settingsManager.toggleSettings()
            #expect(settingsManager.isSettingsOpen == false)
        }
    }

    @Test("Show settings is idempotent")
    func showSettingsIsIdempotent() {
        let settingsManager = SettingsManager()
        settingsManager.showSettings()
        #expect(settingsManager.isSettingsOpen == true)

        settingsManager.showSettings()
        #expect(settingsManager.isSettingsOpen == true)
    }

    @Test("Hide settings is idempotent")
    func hideSettingsIsIdempotent() {
        let settingsManager = SettingsManager()
        #expect(settingsManager.isSettingsOpen == false)

        settingsManager.hideSettings()
        #expect(settingsManager.isSettingsOpen == false)
    }

    @Test("Launch at login updates UserDefaults")
    func launchAtLoginUpdatesUserDefaults() {
        // Clean up before test
        UserDefaults.standard.removeObject(forKey: "launchAtLogin")

        let settingsManager = SettingsManager()
        let initialState = settingsManager.launchAtLogin

        // Toggle the setting
        settingsManager.launchAtLogin = !initialState
        #expect(UserDefaults.standard.bool(forKey: "launchAtLogin") == !initialState)

        // Toggle back
        settingsManager.launchAtLogin = initialState
        #expect(UserDefaults.standard.bool(forKey: "launchAtLogin") == initialState)
    }
}
