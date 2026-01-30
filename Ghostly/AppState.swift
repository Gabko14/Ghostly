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

        KeyboardShortcuts.onKeyDown(for: .selectTab1) { [weak self] in
            Task { @MainActor in
                guard let self = self, !self.isSettingsOpen else { return }
                self.tabManager.selectTabAtIndex(0)
            }
        }

        KeyboardShortcuts.onKeyDown(for: .selectTab2) { [weak self] in
            Task { @MainActor in
                guard let self = self, !self.isSettingsOpen else { return }
                self.tabManager.selectTabAtIndex(1)
            }
        }

        KeyboardShortcuts.onKeyDown(for: .selectTab3) { [weak self] in
            Task { @MainActor in
                guard let self = self, !self.isSettingsOpen else { return }
                self.tabManager.selectTabAtIndex(2)
            }
        }

        KeyboardShortcuts.onKeyDown(for: .nextTab) { [weak self] in
            Task { @MainActor in
                guard let self = self, !self.isSettingsOpen else { return }
                self.tabManager.selectNextTab()
            }
        }

        KeyboardShortcuts.onKeyDown(for: .previousTab) { [weak self] in
            Task { @MainActor in
                guard let self = self, !self.isSettingsOpen else { return }
                self.tabManager.selectPreviousTab()
            }
        }

        // Disable tab shortcuts initially (popover starts closed)
        updateTabShortcuts(enabled: false)
    }

    private func updateTabShortcuts(enabled: Bool) {
        if enabled {
            KeyboardShortcuts.enable(.newTab, .closeTab, .selectTab1, .selectTab2, .selectTab3, .nextTab, .previousTab)
        } else {
            KeyboardShortcuts.disable(.newTab, .closeTab, .selectTab1, .selectTab2, .selectTab3, .nextTab, .previousTab)
        }
    }
}
