//
//  AppState.swift
//  Ghostly
//
//  Created by Ghostly Contributors
//

import SwiftUI
import KeyboardShortcuts

@MainActor
@Observable
final class AppState {
    var isMenuPresented: Bool = false {
        didSet {
            updateTabShortcuts(enabled: isMenuPresented)
        }
    }
    var isSettingsOpen: Bool = false
    let tabManager = TabManager()

    init() {
        KeyboardShortcuts.onKeyUp(for: .toggleGhostly) { [weak self] in
            Task { @MainActor in
                self?.isMenuPresented.toggle()
            }
        }

        KeyboardShortcuts.onKeyDown(for: .newTab) { [weak self] in
            Task { @MainActor in
                guard let self = self, !self.isSettingsOpen else { return }
                self.tabManager.newTab()
            }
        }

        KeyboardShortcuts.onKeyDown(for: .closeTab) { [weak self] in
            Task { @MainActor in
                guard let self = self else { return }
                if self.isSettingsOpen {
                    self.isSettingsOpen = false
                } else {
                    self.tabManager.closeActiveTab()
                }
            }
        }

        // Disable tab shortcuts initially (popover starts closed)
        updateTabShortcuts(enabled: false)
    }

    private func updateTabShortcuts(enabled: Bool) {
        if enabled {
            KeyboardShortcuts.enable(.newTab, .closeTab)
        } else {
            KeyboardShortcuts.disable(.newTab, .closeTab)
        }
    }
}
