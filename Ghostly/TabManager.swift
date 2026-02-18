//
//  TabManager.swift
//  Ghostly
//
//  Created by Ghostly Contributors
//

import Foundation
import OSLog
import SwiftUI

@Observable
@MainActor
final class TabManager {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.ghostly.Ghostly",
        category: "TabManager"
    )

    private(set) var tabs: [GhostlyTab] = []
    var activeTabId: UUID?

    private let userDefaultsKey = "ghostlyTabs"
    private let legacyTextKey = "text"
    private var saveTask: Task<Void, Never>?

    init() {
        loadTabs()
    }

    /// Binding for the active tab's content, suitable for TextEditor
    var activeTabBinding: Binding<String> {
        Binding(
            get: { [weak self] in
                guard let self = self,
                      let activeId = self.activeTabId,
                      let tab = self.tabs.first(where: { $0.id == activeId }) else {
                    return ""
                }
                return tab.content
            },
            set: { [weak self] newValue in
                guard let self = self,
                      let activeId = self.activeTabId,
                      let index = self.tabs.firstIndex(where: { $0.id == activeId }) else {
                    return
                }
                self.tabs[index].content = newValue
                self.debouncedSave()
            }
        )
    }

    /// The currently active tab
    var activeTab: GhostlyTab? {
        guard let activeId = activeTabId else { return nil }
        return tabs.first { $0.id == activeId }
    }

    // MARK: - Tab Operations

    /// Creates a new empty tab, appends it, and makes it active (does not save)
    private func createTab() -> GhostlyTab {
        let tab = GhostlyTab()
        tabs.append(tab)
        activeTabId = tab.id
        return tab
    }

    /// Creates a new empty tab and makes it active
    @discardableResult
    func newTab() -> GhostlyTab {
        let tab = createTab()
        cancelDebouncedSave()
        saveTabs()
        return tab
    }

    /// Closes the specified tab
    func closeTab(_ tabId: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == tabId }) else { return }

        let wasActive = activeTabId == tabId
        tabs.remove(at: index)

        // If we closed the active tab, select an adjacent one
        if wasActive {
            if tabs.isEmpty {
                // If no tabs left, create a new empty one (without saving yet)
                _ = createTab()
            } else {
                // Select the tab at the same index, or the last one if we were at the end
                let newIndex = min(index, tabs.count - 1)
                activeTabId = tabs[newIndex].id
            }
        }

        cancelDebouncedSave()
        saveTabs()
    }

    /// Closes the currently active tab
    func closeActiveTab() {
        guard let activeId = activeTabId else { return }
        closeTab(activeId)
    }

    /// Selects the specified tab
    func selectTab(_ tabId: UUID) {
        guard tabs.contains(where: { $0.id == tabId }) else { return }
        activeTabId = tabId
        cancelDebouncedSave()
        saveTabs()
    }

    /// Selects the tab at the given index (0-based)
    func selectTabAtIndex(_ index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        activeTabId = tabs[index].id
        cancelDebouncedSave()
        saveTabs()
    }

    /// Selects the next tab, wrapping to first if at the end
    func selectNextTab() {
        guard let activeId = activeTabId,
              let currentIndex = tabs.firstIndex(where: { $0.id == activeId }),
              tabs.count > 1 else { return }
        let nextIndex = (currentIndex + 1) % tabs.count
        activeTabId = tabs[nextIndex].id
        cancelDebouncedSave()
        saveTabs()
    }

    /// Selects the previous tab, wrapping to last if at the beginning
    func selectPreviousTab() {
        guard let activeId = activeTabId,
              let currentIndex = tabs.firstIndex(where: { $0.id == activeId }),
              tabs.count > 1 else { return }
        let previousIndex = (currentIndex - 1 + tabs.count) % tabs.count
        activeTabId = tabs[previousIndex].id
        cancelDebouncedSave()
        saveTabs()
    }

    // MARK: - Persistence

    /// Schedules a save after a 500ms delay, cancelling any pending debounced save
    private func debouncedSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard let self, !Task.isCancelled else { return }
            self.saveTabs()
        }
    }

    /// Cancels any pending debounced save to avoid stale overwrites
    private func cancelDebouncedSave() {
        saveTask?.cancel()
        saveTask = nil
    }

    /// Forces any pending debounced content to be saved immediately
    func flushPendingSave() {
        cancelDebouncedSave()
        saveTabs()
    }

    private func loadTabs() {
        // Try to load existing tabs
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedTabs = try? JSONDecoder().decode([GhostlyTab].self, from: data),
           !savedTabs.isEmpty {
            tabs = savedTabs
            // Restore active tab, defaulting to first if not found
            if let savedActiveId = UserDefaults.standard.string(forKey: "\(userDefaultsKey)_activeId"),
               let activeUUID = UUID(uuidString: savedActiveId),
               tabs.contains(where: { $0.id == activeUUID }) {
                activeTabId = activeUUID
            } else {
                activeTabId = tabs.first?.id
            }
            return
        }

        // Migrate from legacy single-document storage
        if let legacyText = UserDefaults.standard.string(forKey: legacyTextKey), !legacyText.isEmpty {
            let migratedTab = GhostlyTab(content: legacyText)
            tabs = [migratedTab]
            activeTabId = migratedTab.id
            saveTabs()
            // Clear legacy storage after migration
            UserDefaults.standard.removeObject(forKey: legacyTextKey)
            return
        }

        // No existing data - create first empty tab
        let initialTab = GhostlyTab()
        tabs = [initialTab]
        activeTabId = initialTab.id
        saveTabs()
    }

    private func saveTabs() {
        do {
            let data = try JSONEncoder().encode(tabs)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            logger.error("Failed to encode tabs for persistence: \(error.localizedDescription, privacy: .public)")
        }
        if let activeId = activeTabId {
            UserDefaults.standard.set(activeId.uuidString, forKey: "\(userDefaultsKey)_activeId")
        }
    }
}
