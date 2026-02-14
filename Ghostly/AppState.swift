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
    let settingsManager = SettingsManager()
    var isSettingsOpen: Bool {
        get { settingsManager.isSettingsOpen }
        set { settingsManager.isSettingsOpen = newValue }
    }
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
        .newTab, .closeTab, .nextTab, .previousTab
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
