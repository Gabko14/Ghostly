//
//  PersistenceModels.swift
//  Ghostly
//

import AppKit
import Foundation

struct PersistedTab: Identifiable, Codable, Equatable {
    let id: UUID
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var sortIndex: Int

    init(
        id: UUID = UUID(),
        content: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        sortIndex: Int
    ) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.sortIndex = sortIndex
    }

    init(tab: GhostlyTab, sortIndex: Int) {
        self.id = tab.id
        self.content = tab.content
        self.createdAt = tab.createdAt
        self.updatedAt = tab.updatedAt
        self.sortIndex = sortIndex
    }
}

extension GhostlyTab {
    init(persistedTab: PersistedTab) {
        self.init(
            id: persistedTab.id,
            content: persistedTab.content,
            createdAt: persistedTab.createdAt,
            updatedAt: persistedTab.updatedAt
        )
    }
}

struct NotesSnapshot: Codable, Equatable {
    var tabs: [PersistedTab]
    var activeTabID: UUID?

    static func fresh(now: Date = Date()) -> NotesSnapshot {
        let tab = PersistedTab(
            content: "",
            createdAt: now,
            updatedAt: now,
            sortIndex: 0
        )
        return NotesSnapshot(tabs: [tab], activeTabID: tab.id)
    }
}

struct NotesChangeSet {
    let upsertedTabs: [PersistedTab]
    let deletedTabIDs: [UUID]
    let activeTabID: UUID?
    let tabRevisions: [UUID: Int]
    let metadataRevision: Int?

    var hasChanges: Bool {
        !upsertedTabs.isEmpty || !deletedTabIDs.isEmpty || metadataRevision != nil
    }
}

enum LaunchState: Equatable {
    case loading
    case ready
    case recovery(RecoveryState)
}

enum RecoveryState: Equatable {
    case storeUnreadable(summary: String, quarantineURL: URL, backupURL: URL?)
    case migrationFailed(summary: String, legacyBackupURL: URL?)
    case restoreInProgress
    case freshStartAvailable(summary: String, quarantineURL: URL)
}

enum FlushReason: String {
    case typingIdle
    case tabSwitch
    case tabCreated
    case tabClosed
    case popoverClosed
    case appResignedActive
    case appTermination
    case manualRecoveryAction
}

enum PersistenceTrigger {
    case scheduleAutosave
    case flush(FlushReason)
}

enum MigrationResult: Equatable {
    case notNeeded
    case noLegacyData
    case migrated(backupURL: URL)
}

enum NotesStoreError: LocalizedError {
    case sqlite(message: String)
    case invalidSchema(foundTables: [String])
    case unreadableStore(String)
    case migrationFailed(String)
    case backupUnavailable
    case exportFailed(String)

    var errorDescription: String? {
        switch self {
        case let .sqlite(message):
            return "SQLite error: \(message)"
        case let .invalidSchema(foundTables):
            return "Invalid notes schema. Found tables: \(foundTables.joined(separator: ", "))"
        case let .unreadableStore(message):
            return "The notes store is unreadable: \(message)"
        case let .migrationFailed(message):
            return "Legacy note migration failed: \(message)"
        case .backupUnavailable:
            return "No backup snapshot is available."
        case let .exportFailed(message):
            return "Recovery bundle export failed: \(message)"
        }
    }
}

@MainActor
final class AppLifecycleDelegate: NSObject, NSApplicationDelegate {
    weak var persistenceCoordinator: PersistenceCoordinator?

    func applicationDidResignActive(_ notification: Notification) {
        guard let persistenceCoordinator else { return }
        Task { await persistenceCoordinator.appDidResignActive() }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let persistenceCoordinator else {
            return .terminateNow
        }

        Task {
            let shouldTerminate = await persistenceCoordinator.handleTerminationRequest()
            sender.reply(toApplicationShouldTerminate: shouldTerminate)
        }
        return .terminateLater
    }
}
