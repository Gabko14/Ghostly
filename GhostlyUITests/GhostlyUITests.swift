//
//  GhostlyUITests.swift
//  GhostlyUITests
//
//  Created by Ghostly Contributors
//

import XCTest

/// UI tests for Ghostly menu bar app.
///
/// Note: Menu bar apps have limited XCUITest support. These tests verify
/// basic app lifecycle. For full UI testing, use manual verification with
/// screenshots as documented in CLAUDE.md.
final class GhostlyUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Verifies the app launches successfully.
    ///
    /// Menu bar apps don't have standard windows, so we verify the process
    /// is running rather than checking for window elements.
    @MainActor func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify app launched successfully
        XCTAssertTrue(app.exists, "App should launch successfully")
    }

    /// Verifies the app terminates cleanly without hanging.
    @MainActor func testAppTerminates() throws {
        let app = XCUIApplication()
        app.launch()

        // Give the app a moment to fully initialize
        _ = app.wait(for: .runningForeground, timeout: 0.5)

        // Verify app can terminate cleanly
        app.terminate()
        XCTAssertFalse(app.exists, "App should terminate cleanly")
    }
}
