//
//  KeyboardShortcuts+Extensions.swift
//  Ghostly
//
//  Created by Ghostly Contributors
//

import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleGhostly = Self("toggleGhostly")
    static let toggleSettings = Self("toggleSettings", default: .init(.comma, modifiers: .command))
}
