//
//  KeyboardShortcutTests.swift
//  GhostlyTests
//
//  Created by Ghostly Contributors
//

import Testing
import KeyboardShortcuts
@testable import Ghostly

@Suite("Keyboard Shortcut Tests")
struct KeyboardShortcutTests {

    // MARK: - Shortcut Name Definition Tests

    @Test("Toggle Ghostly shortcut name is defined")
    func toggleGhostlyShortcutNameIsDefined() {
        let name = KeyboardShortcuts.Name.toggleGhostly
        #expect(name.rawValue == "toggleGhostly")
    }

    // MARK: - Reset Functionality Tests

    @Test("Toggle Ghostly shortcut can be reset")
    func toggleGhostlyShortcutCanBeReset() {
        // Store any existing shortcut
        let existingShortcut = KeyboardShortcuts.getShortcut(for: .toggleGhostly)

        // Reset the shortcut
        KeyboardShortcuts.reset(.toggleGhostly)

        // Verify it's nil after reset (no default for toggleGhostly)
        #expect(KeyboardShortcuts.getShortcut(for: .toggleGhostly) == nil)

        // Restore original if it existed
        if let shortcut = existingShortcut {
            KeyboardShortcuts.setShortcut(shortcut, for: .toggleGhostly)
        }
    }
}
