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
            self?.performTabAction { $0.tabManager.newTab() }
        }

        KeyboardShortcuts.onKeyDown(for: .closeTab) { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                if self.isSettingsOpen {
                    self.isSettingsOpen = false
                } else {
                    self.tabManager.closeActiveTab()
                }
            }
        }

        KeyboardShortcuts.onKeyDown(for: .selectTab1) { [weak self] in
            self?.performTabAction { $0.tabManager.selectTabAtIndex(0) }
        }

        KeyboardShortcuts.onKeyDown(for: .selectTab2) { [weak self] in
            self?.performTabAction { $0.tabManager.selectTabAtIndex(1) }
        }

        KeyboardShortcuts.onKeyDown(for: .selectTab3) { [weak self] in
            self?.performTabAction { $0.tabManager.selectTabAtIndex(2) }
        }

        KeyboardShortcuts.onKeyDown(for: .nextTab) { [weak self] in
            self?.performTabAction { $0.tabManager.selectNextTab() }
        }

        KeyboardShortcuts.onKeyDown(for: .previousTab) { [weak self] in
            self?.performTabAction { $0.tabManager.selectPreviousTab() }
        }

        // Disable tab shortcuts initially (popover starts closed)
        updateTabShortcuts(enabled: false)
    }

    private func performTabAction(_ action: @escaping @MainActor (AppState) -> Void) {
        Task { @MainActor in
            guard !self.isSettingsOpen else { return }
            action(self)
        }
    }

    private static let tabShortcuts: [KeyboardShortcuts.Name] = [
        .newTab, .closeTab, .selectTab1, .selectTab2, .selectTab3, .nextTab, .previousTab
    ]

    private func updateTabShortcuts(enabled: Bool) {
        for shortcut in Self.tabShortcuts {
            if enabled {
                KeyboardShortcuts.enable(shortcut)
            } else {
                KeyboardShortcuts.disable(shortcut)
            }
        }
    }
}
