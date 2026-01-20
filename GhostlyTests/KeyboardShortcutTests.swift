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

    @Test("Toggle Settings shortcut name is defined")
    func toggleSettingsShortcutNameIsDefined() {
        let name = KeyboardShortcuts.Name.toggleSettings
        #expect(name.rawValue == "toggleSettings")
    }

    @Test("Shortcut names are unique")
    func shortcutNamesAreUnique() {
        let toggleGhostly = KeyboardShortcuts.Name.toggleGhostly
        let toggleSettings = KeyboardShortcuts.Name.toggleSettings
        #expect(toggleGhostly.rawValue != toggleSettings.rawValue)
    }

    // MARK: - Default Value Tests

    @Test("Toggle Settings has default shortcut")
    func toggleSettingsHasDefaultShortcut() {
        // Reset to default state first
        KeyboardShortcuts.reset(.toggleSettings)

        // The default is Cmd+,
        let shortcut = KeyboardShortcuts.getShortcut(for: .toggleSettings)
        #expect(shortcut != nil)

        if let shortcut = shortcut {
            #expect(shortcut.key == .comma)
            #expect(shortcut.modifiers.contains(.command))
        }
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

    @Test("Toggle Settings shortcut can be reset to default")
    func toggleSettingsShortcutCanBeResetToDefault() {
        // Store any existing shortcut
        let existingShortcut = KeyboardShortcuts.getShortcut(for: .toggleSettings)

        // Change it to something else
        let testShortcut = KeyboardShortcuts.Shortcut(.a, modifiers: .command)
        KeyboardShortcuts.setShortcut(testShortcut, for: .toggleSettings)

        // Verify the change
        let changedShortcut = KeyboardShortcuts.getShortcut(for: .toggleSettings)
        #expect(changedShortcut?.key == .a)

        // Reset to default
        KeyboardShortcuts.reset(.toggleSettings)

        // Verify it's back to default (Cmd+,)
        let resetShortcut = KeyboardShortcuts.getShortcut(for: .toggleSettings)
        #expect(resetShortcut?.key == .comma)

        // Restore original state
        if let shortcut = existingShortcut {
            KeyboardShortcuts.setShortcut(shortcut, for: .toggleSettings)
        } else {
            KeyboardShortcuts.reset(.toggleSettings)
        }
    }
}
