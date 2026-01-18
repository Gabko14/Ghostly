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

    @Test("Toggle Ghostly shortcut name is defined")
    func toggleGhostlyShortcutNameIsDefined() {
        let name = KeyboardShortcuts.Name.toggleGhostly
        #expect(name.rawValue == "toggleGhostly")
    }

    @Test("Shortcut can be reset")
    func shortcutCanBeReset() {
        // Store any existing shortcut
        let existingShortcut = KeyboardShortcuts.getShortcut(for: .toggleGhostly)

        // Reset the shortcut
        KeyboardShortcuts.reset(.toggleGhostly)

        // Verify it's nil after reset
        #expect(KeyboardShortcuts.getShortcut(for: .toggleGhostly) == nil)

        // Restore original if it existed
        if let shortcut = existingShortcut {
            KeyboardShortcuts.setShortcut(shortcut, for: .toggleGhostly)
        }
    }
}
