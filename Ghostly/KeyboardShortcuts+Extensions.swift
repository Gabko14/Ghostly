//
//  KeyboardShortcuts+Extensions.swift
//  Ghostly
//
//  Created by Ghostly Contributors
//

import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleGhostly = Self("toggleGhostly")
    static let newTab = Self("newTab", default: .init(.t, modifiers: .command))
    static let closeTab = Self("closeTab", default: .init(.w, modifiers: .command))

    // Tab navigation
    static let nextTab = Self("nextTab", default: .init(.rightBracket, modifiers: [.command, .shift]))
    static let previousTab = Self("previousTab", default: .init(.leftBracket, modifiers: [.command, .shift]))
}
