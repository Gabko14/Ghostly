//
//  UpdaterManagerTests.swift
//  GhostlyTests
//
//  Created by Ghostly Contributors
//

import Testing
@testable import Ghostly

@Suite("UpdaterManager Tests")
@MainActor
struct UpdaterManagerTests {

    @Test("Initializes without crashing and canCheckForUpdates starts false")
    func initializesCorrectly() {
        let manager = UpdaterManager()
        #expect(manager.canCheckForUpdates == false)
    }

    @Test("automaticallyChecksForUpdates getter works")
    func automaticallyChecksForUpdatesGetter() {
        let manager = UpdaterManager()
        // Sparkle defaults to true for automaticallyChecksForUpdates
        _ = manager.automaticallyChecksForUpdates
    }
}
