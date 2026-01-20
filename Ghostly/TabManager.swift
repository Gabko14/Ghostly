//
//  TabManager.swift
//  Ghostly
//
//  Created by Ghostly Contributors
//

import Foundation
import SwiftUI

@Observable
@MainActor
class TabManager {
    private(set) var tabs: [GhostlyTab] = []
    var activeTabId: UUID?

    private let userDefaultsKey = "ghostlyTabs"
    private let legacyTextKey = "text"

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
                self.saveTabs()
            }
        )
    }

    /// The currently active tab
    var activeTab: GhostlyTab? {
        guard let activeId = activeTabId else { return nil }
        return tabs.first { $0.id == activeId }
    }

    // MARK: - Tab Operations

    /// Creates a new empty tab and makes it active
    @discardableResult
    func newTab() -> GhostlyTab {
        let tab = GhostlyTab()
        tabs.append(tab)
        activeTabId = tab.id
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
                // If no tabs left, create a new empty one
                newTab()
            } else {
                // Select the tab at the same index, or the last one if we were at the end
                let newIndex = min(index, tabs.count - 1)
                activeTabId = tabs[newIndex].id
            }
        }

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
    }

    // MARK: - Persistence

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
        if let data = try? JSONEncoder().encode(tabs) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
        if let activeId = activeTabId {
            UserDefaults.standard.set(activeId.uuidString, forKey: "\(userDefaultsKey)_activeId")
        }
    }
}
