//
//  NotesStoreTests.swift
//  GhostlyTests
//

import Foundation
import SQLite3
import Testing
@testable import Ghostly

@Suite("NotesStore Tests")
struct NotesStoreTests {
    private func makeEnvironment(now: Date = Date(timeIntervalSince1970: 1_700_000_000)) throws -> (store: NotesStore, rootURL: URL, suiteName: String) {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)

        let suiteName = "GhostlyTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)

        let store = NotesStore(baseDirectory: rootURL, userDefaults: defaults, now: { now })
        return (store, rootURL, suiteName)
    }

    private func makeChangeSet(
        tabs: [PersistedTab],
        activeTabID: UUID?,
        deletedTabIDs: [UUID] = [],
        metadataRevision: Int? = 1
    ) -> NotesChangeSet {
        NotesChangeSet(
            upsertedTabs: tabs,
            deletedTabIDs: deletedTabIDs,
            activeTabID: activeTabID,
            tabRevisions: Dictionary(uniqueKeysWithValues: tabs.enumerated().map { offset, tab in
                (tab.id, offset + 1)
            }),
            metadataRevision: metadataRevision
        )
    }

    private func executeSQL(_ sql: String, at databaseURL: URL) throws {
        var db: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(databaseURL.path, &db, flags, nil) == SQLITE_OK else {
            let message = db.flatMap(sqlite3_errmsg).map(String.init(cString:)) ?? "Unknown SQLite error"
            sqlite3_close(db)
            throw NSError(domain: "NotesStoreTests", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
        }
        defer { sqlite3_close(db) }

        var errorMessage: UnsafeMutablePointer<Int8>?
        guard sqlite3_exec(db, sql, nil, nil, &errorMessage) == SQLITE_OK else {
            let message = errorMessage.map { String(cString: $0) } ?? "Unknown SQLite error"
            sqlite3_free(errorMessage)
            throw NSError(domain: "NotesStoreTests", code: 2, userInfo: [NSLocalizedDescriptionKey: message])
        }
    }

    @Test("Fresh store loads as one empty active tab")
    func freshStoreLoadsAsEmptyWorkspace() async throws {
        let environment = try makeEnvironment()
        defer {
            UserDefaults(suiteName: environment.suiteName)?.removePersistentDomain(forName: environment.suiteName)
            try? FileManager.default.removeItem(at: environment.rootURL)
        }

        try await environment.store.open()
        let snapshot = try await environment.store.loadSnapshot()

        #expect(snapshot.tabs.count == 1)
        #expect(snapshot.tabs.first?.content == "")
        #expect(snapshot.activeTabID == snapshot.tabs.first?.id)
    }

    @Test("Fresh store is no longer considered migratable after initial load")
    func freshStoreStopsReportingAsFreshAfterLoad() async throws {
        let environment = try makeEnvironment()
        defer {
            UserDefaults(suiteName: environment.suiteName)?.removePersistentDomain(forName: environment.suiteName)
            try? FileManager.default.removeItem(at: environment.rootURL)
        }

        try await environment.store.open()
        _ = try await environment.store.loadSnapshot()

        let secondMigrationCheck = try await environment.store.migrateLegacyUserDefaultsIfNeeded()
        #expect(secondMigrationCheck == .notNeeded)
    }

    @Test("Store round-trips persisted tabs and active tab")
    func storeRoundTripsSnapshot() async throws {
        let environment = try makeEnvironment()
        defer {
            UserDefaults(suiteName: environment.suiteName)?.removePersistentDomain(forName: environment.suiteName)
            try? FileManager.default.removeItem(at: environment.rootURL)
        }

        let first = PersistedTab(
            id: UUID(),
            content: "First note",
            createdAt: Date(timeIntervalSince1970: 10),
            updatedAt: Date(timeIntervalSince1970: 11),
            sortIndex: 0
        )
        let second = PersistedTab(
            id: UUID(),
            content: "Second note",
            createdAt: Date(timeIntervalSince1970: 20),
            updatedAt: Date(timeIntervalSince1970: 21),
            sortIndex: 1
        )
        let expected = NotesSnapshot(tabs: [first, second], activeTabID: second.id)

        try await environment.store.open()
        try await environment.store.save(makeChangeSet(tabs: expected.tabs, activeTabID: expected.activeTabID), writeBackup: true)
        let loaded = try await environment.store.loadSnapshot()

        #expect(loaded == expected)
        #expect(await environment.store.latestBackupIfAvailable() != nil)
    }

    @Test("Legacy text migrates into SQLite and clears old defaults")
    func legacyTextMigratesIntoStore() async throws {
        let environment = try makeEnvironment(now: Date(timeIntervalSince1970: 42))
        defer {
            UserDefaults(suiteName: environment.suiteName)?.removePersistentDomain(forName: environment.suiteName)
            try? FileManager.default.removeItem(at: environment.rootURL)
        }

        let legacyDefaults = try #require(UserDefaults(suiteName: environment.suiteName))
        legacyDefaults.set("Legacy note", forKey: "text")

        try await environment.store.open()
        let result = try await environment.store.migrateLegacyUserDefaultsIfNeeded()
        let snapshot = try await environment.store.loadSnapshot()

        if case let .migrated(backupURL) = result {
            #expect(FileManager.default.fileExists(atPath: backupURL.path))
        } else {
            #expect(Bool(false))
        }

        #expect(snapshot.tabs.count == 1)
        #expect(snapshot.tabs.first?.content == "Legacy note")
        #expect(snapshot.activeTabID == snapshot.tabs.first?.id)
        let verificationDefaults = try #require(UserDefaults(suiteName: environment.suiteName))
        #expect(verificationDefaults.string(forKey: "text") == nil)
        #expect(await environment.store.lastMigrationBackupIfAvailable() != nil)
    }

    @Test("Schema-only store still migrates legacy data on next launch")
    func schemaOnlyStoreStillMigratesLegacyData() async throws {
        let environment = try makeEnvironment(now: Date(timeIntervalSince1970: 99))
        defer {
            UserDefaults(suiteName: environment.suiteName)?.removePersistentDomain(forName: environment.suiteName)
            try? FileManager.default.removeItem(at: environment.rootURL)
        }

        let legacyDefaults = try #require(UserDefaults(suiteName: environment.suiteName))
        legacyDefaults.set("Recovered legacy note", forKey: "text")

        try await environment.store.open()
        await environment.store.close()

        try await environment.store.open()
        let result = try await environment.store.migrateLegacyUserDefaultsIfNeeded()
        let snapshot = try await environment.store.loadSnapshot()

        if case .migrated = result {
            #expect(snapshot.tabs.first?.content == "Recovered legacy note")
        } else {
            #expect(Bool(false))
        }
    }

    @Test("Empty legacy tabs payload does not clear fallback data")
    func emptyLegacyTabsPayloadDoesNotClearFallbackData() async throws {
        let environment = try makeEnvironment(now: Date(timeIntervalSince1970: 123))
        defer {
            UserDefaults(suiteName: environment.suiteName)?.removePersistentDomain(forName: environment.suiteName)
            try? FileManager.default.removeItem(at: environment.rootURL)
        }

        let defaults = try #require(UserDefaults(suiteName: environment.suiteName))
        defaults.set(try JSONEncoder().encode([GhostlyTab]()), forKey: "ghostlyTabs")
        defaults.set("Fallback note", forKey: "text")

        try await environment.store.open()

        do {
            _ = try await environment.store.migrateLegacyUserDefaultsIfNeeded()
            #expect(Bool(false))
        } catch let error as NotesStoreError {
            #expect(error.errorDescription == "Legacy note migration failed: Legacy tabs payload is empty.")
        }

        let verificationDefaults = try #require(UserDefaults(suiteName: environment.suiteName))
        #expect(verificationDefaults.string(forKey: "text") == "Fallback note")
        #expect(verificationDefaults.data(forKey: "ghostlyTabs") != nil)
    }

    @Test("Load normalizes invalid active tab and dense sort indexes")
    func loadNormalizesMetadataAndSortIndexes() async throws {
        let environment = try makeEnvironment()
        defer {
            UserDefaults(suiteName: environment.suiteName)?.removePersistentDomain(forName: environment.suiteName)
            try? FileManager.default.removeItem(at: environment.rootURL)
        }

        let first = PersistedTab(
            id: UUID(),
            content: "First",
            createdAt: Date(timeIntervalSince1970: 1),
            updatedAt: Date(timeIntervalSince1970: 2),
            sortIndex: 0
        )
        let second = PersistedTab(
            id: UUID(),
            content: "Second",
            createdAt: Date(timeIntervalSince1970: 3),
            updatedAt: Date(timeIntervalSince1970: 4),
            sortIndex: 1
        )

        try await environment.store.open()
        try await environment.store.save(makeChangeSet(tabs: [first, second], activeTabID: second.id), writeBackup: false)
        await environment.store.close()

        let databaseURL = await environment.store.databaseURL
        try executeSQL(
            """
            UPDATE tabs SET sort_index = 10 WHERE id = '\(first.id.uuidString)';
            UPDATE tabs SET sort_index = 20 WHERE id = '\(second.id.uuidString)';
            UPDATE app_metadata SET value = 'not-a-uuid' WHERE key = 'active_tab_id';
            """,
            at: databaseURL
        )

        try await environment.store.open()
        let normalized = try await environment.store.loadSnapshot()

        #expect(normalized.tabs.map(\.sortIndex) == [0, 1])
        #expect(normalized.activeTabID == first.id)
    }

    @Test("Restore from backup rebuilds the store from the last good snapshot")
    func restoreFromBackupRebuildsStore() async throws {
        let environment = try makeEnvironment()
        defer {
            UserDefaults(suiteName: environment.suiteName)?.removePersistentDomain(forName: environment.suiteName)
            try? FileManager.default.removeItem(at: environment.rootURL)
        }

        let original = PersistedTab(
            id: UUID(),
            content: "Original",
            createdAt: Date(timeIntervalSince1970: 5),
            updatedAt: Date(timeIntervalSince1970: 6),
            sortIndex: 0
        )
        let updated = PersistedTab(
            id: original.id,
            content: "Updated",
            createdAt: original.createdAt,
            updatedAt: Date(timeIntervalSince1970: 7),
            sortIndex: 0
        )

        try await environment.store.open()
        try await environment.store.save(makeChangeSet(tabs: [original], activeTabID: original.id), writeBackup: true)
        try await environment.store.save(makeChangeSet(tabs: [updated], activeTabID: updated.id), writeBackup: false)

        let liveSnapshot = try await environment.store.loadSnapshot()
        #expect(liveSnapshot.tabs.first?.content == "Updated")

        let restored = try await environment.store.restoreFromLatestBackup()

        #expect(restored.tabs.first?.content == "Original")
        #expect(restored.activeTabID == original.id)
    }

    @Test("Quarantine moves the unreadable store aside without deleting it")
    func quarantineMovesStoreFiles() async throws {
        let environment = try makeEnvironment()
        defer {
            UserDefaults(suiteName: environment.suiteName)?.removePersistentDomain(forName: environment.suiteName)
            try? FileManager.default.removeItem(at: environment.rootURL)
        }

        let tab = PersistedTab(
            id: UUID(),
            content: "Quarantine me",
            createdAt: Date(timeIntervalSince1970: 8),
            updatedAt: Date(timeIntervalSince1970: 9),
            sortIndex: 0
        )

        try await environment.store.open()
        try await environment.store.save(makeChangeSet(tabs: [tab], activeTabID: tab.id), writeBackup: true)

        let databaseURL = await environment.store.databaseURL
        let quarantineURL = try await environment.store.quarantineCurrentStore(reason: "Test")

        #expect(!FileManager.default.fileExists(atPath: databaseURL.path))
        #expect(FileManager.default.fileExists(atPath: quarantineURL.appendingPathComponent("notes.sqlite").path))
        #expect(FileManager.default.fileExists(atPath: quarantineURL.appendingPathComponent("metadata.txt").path))
    }
}
