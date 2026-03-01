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
final class TabManager {
    private(set) var tabs: [GhostlyTab]
    var activeTabId: UUID?

    var onPersistenceTrigger: ((PersistenceTrigger) -> Void)?

    private var deletedTabIDs = Set<UUID>()
    private var dirtyTabRevisions: [UUID: Int] = [:]
    private var metadataRevision: Int?
    private var revisionCounter = 0
    private var isHydrating = false

    init() {
        let initialTab = GhostlyTab()
        self.tabs = [initialTab]
        self.activeTabId = initialTab.id
    }

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

                let transformedValue = newValue
                guard self.tabs[index].content != transformedValue else { return }

                self.tabs[index].content = transformedValue
                self.tabs[index].updatedAt = Date()
                self.markTabDirty(activeId)
                self.onPersistenceTrigger?(.scheduleAutosave)
            }
        )
    }

    var activeTab: GhostlyTab? {
        guard let activeId = activeTabId else { return nil }
        return tabs.first { $0.id == activeId }
    }

    var hasDirtyChanges: Bool {
        !dirtyTabRevisions.isEmpty || !deletedTabIDs.isEmpty || metadataRevision != nil
    }

    @discardableResult
    func newTab() -> GhostlyTab {
        let tab = GhostlyTab()
        tabs.append(tab)
        activeTabId = tab.id
        markTabDirty(tab.id)
        markMetadataDirty()
        requestImmediateFlush(.tabCreated)
        return tab
    }

    func closeTab(_ tabId: UUID) {
        guard let index = tabs.firstIndex(where: { $0.id == tabId }) else { return }

        let wasActive = activeTabId == tabId
        tabs.remove(at: index)
        deletedTabIDs.insert(tabId)
        dirtyTabRevisions.removeValue(forKey: tabId)

        if wasActive {
            if tabs.isEmpty {
                let replacement = GhostlyTab()
                tabs = [replacement]
                markTabDirty(replacement.id)
                activeTabId = replacement.id
            } else {
                let newIndex = min(index, tabs.count - 1)
                activeTabId = tabs[newIndex].id
            }
        }

        markAllTabsDirty()
        markMetadataDirty()
        requestImmediateFlush(.tabClosed)
    }

    func closeActiveTab() {
        guard let activeId = activeTabId else { return }
        closeTab(activeId)
    }

    func selectTab(_ tabId: UUID) {
        guard tabs.contains(where: { $0.id == tabId }), activeTabId != tabId else { return }
        activeTabId = tabId
        markMetadataDirty()
        requestImmediateFlush(.tabSwitch)
    }

    func selectTabAtIndex(_ index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        selectTab(tabs[index].id)
    }

    func selectNextTab() {
        guard let activeId = activeTabId,
              let currentIndex = tabs.firstIndex(where: { $0.id == activeId }),
              tabs.count > 1 else { return }
        let nextIndex = (currentIndex + 1) % tabs.count
        selectTab(tabs[nextIndex].id)
    }

    func selectPreviousTab() {
        guard let activeId = activeTabId,
              let currentIndex = tabs.firstIndex(where: { $0.id == activeId }),
              tabs.count > 1 else { return }
        let previousIndex = (currentIndex - 1 + tabs.count) % tabs.count
        selectTab(tabs[previousIndex].id)
    }

    func load(snapshot: NotesSnapshot) {
        isHydrating = true
        tabs = snapshot.tabs.sorted { $0.sortIndex < $1.sortIndex }.map(GhostlyTab.init(persistedTab:))
        if tabs.isEmpty {
            let initialTab = GhostlyTab()
            tabs = [initialTab]
            activeTabId = initialTab.id
        } else if let activeTabID = snapshot.activeTabID,
                  tabs.contains(where: { $0.id == activeTabID }) {
            activeTabId = activeTabID
        } else {
            activeTabId = tabs.first?.id
        }
        clearDirtyState()
        isHydrating = false
    }

    func currentSnapshot() -> NotesSnapshot {
        NotesSnapshot(
            tabs: tabs.enumerated().map { index, tab in PersistedTab(tab: tab, sortIndex: index) },
            activeTabID: activeTabId
        )
    }

    func currentChangeSet() -> NotesChangeSet {
        let upsertedTabs = tabs.enumerated().compactMap { index, tab -> PersistedTab? in
            guard dirtyTabRevisions[tab.id] != nil else { return nil }
            return PersistedTab(tab: tab, sortIndex: index)
        }

        return NotesChangeSet(
            upsertedTabs: upsertedTabs,
            deletedTabIDs: Array(deletedTabIDs),
            activeTabID: activeTabId,
            tabRevisions: dirtyTabRevisions,
            metadataRevision: metadataRevision
        )
    }

    func markPersisted(_ changeSet: NotesChangeSet) {
        for tab in changeSet.upsertedTabs {
            guard let revision = changeSet.tabRevisions[tab.id],
                  dirtyTabRevisions[tab.id] == revision else {
                continue
            }
            dirtyTabRevisions.removeValue(forKey: tab.id)
        }

        for deletedID in changeSet.deletedTabIDs {
            deletedTabIDs.remove(deletedID)
        }

        if let metadataRevision, changeSet.metadataRevision == metadataRevision {
            self.metadataRevision = nil
        }
    }

    private func requestImmediateFlush(_ reason: FlushReason) {
        guard !isHydrating else { return }
        onPersistenceTrigger?(.flush(reason))
    }

    private func markTabDirty(_ tabID: UUID) {
        revisionCounter += 1
        dirtyTabRevisions[tabID] = revisionCounter
    }

    private func markMetadataDirty() {
        revisionCounter += 1
        metadataRevision = revisionCounter
    }

    private func markAllTabsDirty() {
        for tab in tabs {
            markTabDirty(tab.id)
        }
    }

    private func clearDirtyState() {
        deletedTabIDs.removeAll()
        dirtyTabRevisions.removeAll()
        metadataRevision = nil
    }
}
