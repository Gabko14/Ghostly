//
//  NotesStore.swift
//  Ghostly
//

import Foundation
import OSLog
import SQLite3

actor NotesStore {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.ghostly.Ghostly",
        category: "NotesStore"
    )

    private let fileManager: FileManager
    private let userDefaults: UserDefaults
    private let rootDirectoryURL: URL
    private let now: @Sendable () -> Date

    private let legacyTabsKey = "ghostlyTabs"
    private let legacyActiveTabKey = "ghostlyTabs_activeId"
    private let legacyTextKey = "text"

    private let schemaVersion = "1"
    private let expectedTables: Set<String> = ["tabs", "app_metadata"]

    private var db: OpaquePointer?
    private var openedFreshStore = false
    private var lastQuarantineURL: URL?
    private var lastMigrationBackupURL: URL?

    init(
        baseDirectory: URL? = nil,
        userDefaults: UserDefaults = .standard,
        fileManager: FileManager = .default,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.fileManager = fileManager
        self.userDefaults = userDefaults
        self.now = now
        if let baseDirectory {
            self.rootDirectoryURL = baseDirectory
        } else {
            self.rootDirectoryURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory())
        }
    }

    var storeDirectoryURL: URL {
        rootDirectoryURL.appendingPathComponent("Ghostly", isDirectory: true)
    }

    var databaseURL: URL {
        storeDirectoryURL.appendingPathComponent("notes.sqlite")
    }

    var backupsDirectoryURL: URL {
        storeDirectoryURL.appendingPathComponent("Backups", isDirectory: true)
    }

    var quarantineDirectoryURL: URL {
        storeDirectoryURL.appendingPathComponent("Quarantine", isDirectory: true)
    }

    var latestBackupURL: URL {
        backupsDirectoryURL.appendingPathComponent("latest-good-snapshot.json")
    }

    func open() throws {
        guard db == nil else { return }

        try fileManager.createDirectory(at: storeDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        try fileManager.createDirectory(at: backupsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        try fileManager.createDirectory(at: quarantineDirectoryURL, withIntermediateDirectories: true, attributes: nil)

        let databaseExisted = fileManager.fileExists(atPath: databaseURL.path)

        var connection: OpaquePointer?
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        if sqlite3_open_v2(databaseURL.path, &connection, flags, nil) != SQLITE_OK {
            let message = Self.sqliteMessage(from: connection)
            sqlite3_close(connection)
            throw NotesStoreError.sqlite(message: message)
        }

        db = connection
        openedFreshStore = !databaseExisted

        do {
            try executeStatements(
                """
                PRAGMA foreign_keys = ON;
                PRAGMA journal_mode = WAL;
                PRAGMA synchronous = NORMAL;
                """
            )
            try initializeSchema()
        } catch {
            closeConnection()
            throw error
        }
    }

    func close() {
        closeConnection()
    }

    func loadSnapshot() throws -> NotesSnapshot {
        try open()
        try quickCheck()

        var snapshot = NotesSnapshot(
            tabs: try fetchTabs().sorted {
                if $0.sortIndex == $1.sortIndex {
                    if $0.createdAt == $1.createdAt {
                        return $0.id.uuidString < $1.id.uuidString
                    }
                    return $0.createdAt < $1.createdAt
                }
                return $0.sortIndex < $1.sortIndex
            },
            activeTabID: try fetchActiveTabID()
        )

        var requiresNormalization = false
        snapshot.tabs = normalizeSortIndexes(snapshot.tabs, changed: &requiresNormalization)

        if snapshot.tabs.isEmpty {
            snapshot = NotesSnapshot.fresh(now: now())
            requiresNormalization = true
        }

        if snapshot.activeTabID == nil || !snapshot.tabs.contains(where: { $0.id == snapshot.activeTabID }) {
            snapshot.activeTabID = snapshot.tabs.first?.id
            requiresNormalization = true
        }

        if requiresNormalization {
            try writeFullSnapshot(snapshot)
        }

        return snapshot
    }

    func save(_ changeSet: NotesChangeSet, writeBackup: Bool) throws {
        guard changeSet.hasChanges else { return }
        try open()

        try beginImmediateTransaction()
        do {
            for deletedID in changeSet.deletedTabIDs {
                try execute(
                    "DELETE FROM tabs WHERE id = ?;",
                    bind: { statement in
                        self.bind(text: deletedID.uuidString, at: 1, in: statement)
                    }
                )
            }

            for tab in changeSet.upsertedTabs {
                try execute(
                    """
                    INSERT INTO tabs (id, content, created_at, updated_at, sort_index)
                    VALUES (?, ?, ?, ?, ?)
                    ON CONFLICT(id) DO UPDATE SET
                        content = excluded.content,
                        created_at = excluded.created_at,
                        updated_at = excluded.updated_at,
                        sort_index = excluded.sort_index;
                    """,
                    bind: { statement in
                        self.bind(text: tab.id.uuidString, at: 1, in: statement)
                        self.bind(text: tab.content, at: 2, in: statement)
                        sqlite3_bind_double(statement, 3, tab.createdAt.timeIntervalSince1970)
                        sqlite3_bind_double(statement, 4, tab.updatedAt.timeIntervalSince1970)
                        sqlite3_bind_int64(statement, 5, sqlite3_int64(tab.sortIndex))
                    }
                )
            }

            if let activeTabID = changeSet.activeTabID {
                try setMetadata(activeTabID.uuidString, for: "active_tab_id")
            } else {
                try deleteMetadata(for: "active_tab_id")
            }

            try commitTransaction()
        } catch {
            try? rollbackTransaction()
            throw error
        }

        if writeBackup {
            try writeLatestBackupSnapshot(loadSnapshot())
        }
    }

    func flush() throws {
        guard let db else { return }
        let result = sqlite3_wal_checkpoint_v2(db, nil, SQLITE_CHECKPOINT_PASSIVE, nil, nil)
        guard result == SQLITE_OK else {
            throw NotesStoreError.sqlite(message: Self.sqliteMessage(from: db))
        }
    }

    func migrateLegacyUserDefaultsIfNeeded() throws -> MigrationResult {
        try open()
        guard openedFreshStore else { return .notNeeded }

        if let data = userDefaults.data(forKey: legacyTabsKey) {
            do {
                let legacyTabs = try JSONDecoder().decode([GhostlyTab].self, from: data)
                let activeTabID = userDefaults.string(forKey: legacyActiveTabKey).flatMap(UUID.init(uuidString:))
                let snapshot = NotesSnapshot(
                    tabs: legacyTabs.enumerated().map { index, tab in
                        PersistedTab(
                            id: tab.id,
                            content: tab.content,
                            createdAt: tab.createdAt,
                            updatedAt: tab.updatedAt,
                            sortIndex: index
                        )
                    },
                    activeTabID: activeTabID
                )
                let backupURL = try writeMigrationBackup(snapshot)
                try writeFullSnapshot(snapshot)
                clearLegacyDefaults()
                openedFreshStore = false
                return .migrated(backupURL: backupURL)
            } catch {
                try resetFreshStoreAfterFailure()
                throw NotesStoreError.migrationFailed(error.localizedDescription)
            }
        }

        if let legacyText = userDefaults.string(forKey: legacyTextKey), !legacyText.isEmpty {
            let timestamp = now()
            let snapshot = NotesSnapshot(
                tabs: [
                    PersistedTab(
                        content: legacyText,
                        createdAt: timestamp,
                        updatedAt: timestamp,
                        sortIndex: 0
                    )
                ],
                activeTabID: nil
            )
            do {
                let backupURL = try writeMigrationBackup(snapshot)
                try writeFullSnapshot(snapshot)
                clearLegacyDefaults()
                openedFreshStore = false
                return .migrated(backupURL: backupURL)
            } catch {
                try resetFreshStoreAfterFailure()
                throw NotesStoreError.migrationFailed(error.localizedDescription)
            }
        }

        return .noLegacyData
    }

    func createFreshStore() throws -> NotesSnapshot {
        closeConnection()
        try removeStoreFiles()
        try open()
        let snapshot = NotesSnapshot.fresh(now: now())
        try writeFullSnapshot(snapshot)
        try writeLatestBackupSnapshot(snapshot)
        openedFreshStore = false
        return snapshot
    }

    func restoreFromLatestBackup() throws -> NotesSnapshot {
        guard fileManager.fileExists(atPath: latestBackupURL.path) else {
            throw NotesStoreError.backupUnavailable
        }

        let data = try Data(contentsOf: latestBackupURL)
        let snapshot = try JSONDecoder().decode(NotesSnapshot.self, from: data)

        closeConnection()
        try removeStoreFiles()
        try open()
        try writeFullSnapshot(snapshot)
        try writeLatestBackupSnapshot(snapshot)
        openedFreshStore = false
        return try loadSnapshot()
    }

    func quarantineCurrentStore(reason: String) throws -> URL {
        closeConnection()

        let timestamp = ISO8601DateFormatter().string(from: now()).replacingOccurrences(of: ":", with: "-")
        let directory = quarantineDirectoryURL.appendingPathComponent(timestamp, isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)

        let urls = [databaseURL, sidecarURL(suffix: "-wal"), sidecarURL(suffix: "-shm")]

        for url in urls where fileManager.fileExists(atPath: url.path) {
            let targetURL = directory.appendingPathComponent(url.lastPathComponent)
            if fileManager.fileExists(atPath: targetURL.path) {
                try fileManager.removeItem(at: targetURL)
            }
            try fileManager.moveItem(at: url, to: targetURL)
        }

        let metadataURL = directory.appendingPathComponent("metadata.txt")
        try """
        reason: \(reason)
        created_at: \(ISO8601DateFormatter().string(from: now()))
        """.write(to: metadataURL, atomically: true, encoding: .utf8)

        lastQuarantineURL = directory
        return directory
    }

    func exportRecoveryBundle(to destination: URL) throws {
        let timestamp = ISO8601DateFormatter().string(from: now()).replacingOccurrences(of: ":", with: "-")
        let bundleURL = destination.appendingPathComponent("Ghostly Recovery \(timestamp)", isDirectory: true)
        try fileManager.createDirectory(at: bundleURL, withIntermediateDirectories: true, attributes: nil)

        if let lastQuarantineURL {
            let target = bundleURL.appendingPathComponent("Quarantine", isDirectory: true)
            try copyDirectoryContents(at: lastQuarantineURL, to: target)
        }

        if fileManager.fileExists(atPath: latestBackupURL.path) {
            try fileManager.copyItem(
                at: latestBackupURL,
                to: bundleURL.appendingPathComponent(latestBackupURL.lastPathComponent)
            )
        }

        let metadataURL = bundleURL.appendingPathComponent("recovery-metadata.txt")
        try """
        exported_at: \(ISO8601DateFormatter().string(from: now()))
        quarantine_present: \(lastQuarantineURL != nil)
        latest_backup_present: \(fileManager.fileExists(atPath: latestBackupURL.path))
        """.write(to: metadataURL, atomically: true, encoding: .utf8)
    }

    func latestBackupIfAvailable() -> URL? {
        fileManager.fileExists(atPath: latestBackupURL.path) ? latestBackupURL : nil
    }

    func lastMigrationBackupIfAvailable() -> URL? {
        lastMigrationBackupURL
    }

    private func initializeSchema() throws {
        let existingTables = try fetchUserTables()
        if !existingTables.isEmpty, !expectedTables.isSubset(of: existingTables) {
            throw NotesStoreError.invalidSchema(foundTables: existingTables.sorted())
        }

        try executeStatements(
            """
            CREATE TABLE IF NOT EXISTS tabs (
                id TEXT PRIMARY KEY,
                content TEXT NOT NULL,
                created_at REAL NOT NULL,
                updated_at REAL NOT NULL,
                sort_index INTEGER NOT NULL
            );

            CREATE TABLE IF NOT EXISTS app_metadata (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            );

            CREATE UNIQUE INDEX IF NOT EXISTS tabs_sort_index_idx ON tabs(sort_index);
            """
        )

        try setMetadata(schemaVersion, for: "schema_version")
    }

    private func fetchUserTables() throws -> Set<String> {
        try queryStrings("SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%';")
    }

    private func quickCheck() throws {
        let result = try querySingleString("PRAGMA quick_check;")
        guard result == "ok" else {
            throw NotesStoreError.unreadableStore(result ?? "quick_check failed")
        }
    }

    private func fetchTabs() throws -> [PersistedTab] {
        guard let db else { throw NotesStoreError.sqlite(message: "Database is not open") }

        let sql = "SELECT id, content, created_at, updated_at, sort_index FROM tabs ORDER BY sort_index ASC, created_at ASC, id ASC;"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NotesStoreError.sqlite(message: Self.sqliteMessage(from: db))
        }
        defer { sqlite3_finalize(statement) }

        var tabs: [PersistedTab] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let idCString = sqlite3_column_text(statement, 0),
                  let contentCString = sqlite3_column_text(statement, 1),
                  let id = UUID(uuidString: String(cString: idCString)) else {
                throw NotesStoreError.unreadableStore("A persisted tab row is malformed.")
            }

            tabs.append(
                PersistedTab(
                    id: id,
                    content: String(cString: contentCString),
                    createdAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 2)),
                    updatedAt: Date(timeIntervalSince1970: sqlite3_column_double(statement, 3)),
                    sortIndex: Int(sqlite3_column_int64(statement, 4))
                )
            )
        }
        return tabs
    }

    private func fetchActiveTabID() throws -> UUID? {
        guard let value = try querySingleString("SELECT value FROM app_metadata WHERE key = 'active_tab_id';"),
              let activeID = UUID(uuidString: value) else {
            return nil
        }
        return activeID
    }

    private func writeFullSnapshot(_ snapshot: NotesSnapshot) throws {
        try beginImmediateTransaction()
        do {
            try execute("DELETE FROM tabs;")
            for tab in snapshot.tabs {
                try execute(
                    "INSERT INTO tabs (id, content, created_at, updated_at, sort_index) VALUES (?, ?, ?, ?, ?);",
                    bind: { statement in
                        self.bind(text: tab.id.uuidString, at: 1, in: statement)
                        self.bind(text: tab.content, at: 2, in: statement)
                        sqlite3_bind_double(statement, 3, tab.createdAt.timeIntervalSince1970)
                        sqlite3_bind_double(statement, 4, tab.updatedAt.timeIntervalSince1970)
                        sqlite3_bind_int64(statement, 5, sqlite3_int64(tab.sortIndex))
                    }
                )
            }

            if let activeTabID = snapshot.activeTabID {
                try setMetadata(activeTabID.uuidString, for: "active_tab_id")
            } else {
                try deleteMetadata(for: "active_tab_id")
            }

            try commitTransaction()
        } catch {
            try? rollbackTransaction()
            throw error
        }
    }

    private func normalizeSortIndexes(_ tabs: [PersistedTab], changed: inout Bool) -> [PersistedTab] {
        tabs.enumerated().map { index, tab in
            guard tab.sortIndex != index else { return tab }
            changed = true
            var normalized = tab
            normalized.sortIndex = index
            return normalized
        }
    }

    private func writeLatestBackupSnapshot(_ snapshot: NotesSnapshot) throws {
        let data = try JSONEncoder().encode(snapshot)
        let tempURL = latestBackupURL.appendingPathExtension("tmp")
        try data.write(to: tempURL, options: .atomic)
        if fileManager.fileExists(atPath: latestBackupURL.path) {
            try fileManager.removeItem(at: latestBackupURL)
        }
        try fileManager.moveItem(at: tempURL, to: latestBackupURL)
    }

    private func writeMigrationBackup(_ snapshot: NotesSnapshot) throws -> URL {
        let timestamp = ISO8601DateFormatter().string(from: now()).replacingOccurrences(of: ":", with: "-")
        let url = backupsDirectoryURL.appendingPathComponent("migration-\(timestamp).json")
        let data = try JSONEncoder().encode(snapshot)
        try data.write(to: url, options: .atomic)
        lastMigrationBackupURL = url
        return url
    }

    private func clearLegacyDefaults() {
        userDefaults.removeObject(forKey: legacyTabsKey)
        userDefaults.removeObject(forKey: legacyActiveTabKey)
        userDefaults.removeObject(forKey: legacyTextKey)
    }

    private func resetFreshStoreAfterFailure() throws {
        closeConnection()
        try removeStoreFiles()
        openedFreshStore = false
    }

    private func removeStoreFiles() throws {
        let urls = [databaseURL, sidecarURL(suffix: "-wal"), sidecarURL(suffix: "-shm")]
        for url in urls where fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    private func copyDirectoryContents(at source: URL, to destination: URL) throws {
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true, attributes: nil)
        for url in try fileManager.contentsOfDirectory(at: source, includingPropertiesForKeys: nil) {
            let targetURL = destination.appendingPathComponent(url.lastPathComponent)
            if fileManager.fileExists(atPath: targetURL.path) {
                try fileManager.removeItem(at: targetURL)
            }
            try fileManager.copyItem(at: url, to: targetURL)
        }
    }

    private func beginImmediateTransaction() throws {
        try execute("BEGIN IMMEDIATE TRANSACTION;")
    }

    private func commitTransaction() throws {
        try execute("COMMIT;")
    }

    private func rollbackTransaction() throws {
        try execute("ROLLBACK;")
    }

    private func setMetadata(_ value: String, for key: String) throws {
        try execute(
            """
            INSERT INTO app_metadata (key, value) VALUES (?, ?)
            ON CONFLICT(key) DO UPDATE SET value = excluded.value;
            """,
            bind: { statement in
                self.bind(text: key, at: 1, in: statement)
                self.bind(text: value, at: 2, in: statement)
            }
        )
    }

    private func deleteMetadata(for key: String) throws {
        try execute(
            "DELETE FROM app_metadata WHERE key = ?;",
            bind: { statement in
                self.bind(text: key, at: 1, in: statement)
            }
        )
    }

    private func queryStrings(_ sql: String) throws -> Set<String> {
        guard let db else { throw NotesStoreError.sqlite(message: "Database is not open") }

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NotesStoreError.sqlite(message: Self.sqliteMessage(from: db))
        }
        defer { sqlite3_finalize(statement) }

        var strings = Set<String>()
        while sqlite3_step(statement) == SQLITE_ROW {
            if let cString = sqlite3_column_text(statement, 0) {
                strings.insert(String(cString: cString))
            }
        }
        return strings
    }

    private func querySingleString(_ sql: String) throws -> String? {
        guard let db else { throw NotesStoreError.sqlite(message: "Database is not open") }

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NotesStoreError.sqlite(message: Self.sqliteMessage(from: db))
        }
        defer { sqlite3_finalize(statement) }

        guard sqlite3_step(statement) == SQLITE_ROW,
              let cString = sqlite3_column_text(statement, 0) else {
            return nil
        }
        return String(cString: cString)
    }

    private func execute(_ sql: String, bind: ((OpaquePointer?) -> Void)? = nil) throws {
        guard let db else { throw NotesStoreError.sqlite(message: "Database is not open") }

        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw NotesStoreError.sqlite(message: Self.sqliteMessage(from: db))
        }
        defer { sqlite3_finalize(statement) }

        bind?(statement)

        let result = sqlite3_step(statement)
        guard result == SQLITE_DONE || result == SQLITE_ROW else {
            throw NotesStoreError.sqlite(message: Self.sqliteMessage(from: db))
        }
    }

    private func executeStatements(_ sql: String) throws {
        guard let db else { throw NotesStoreError.sqlite(message: "Database is not open") }

        var errorMessage: UnsafeMutablePointer<Int8>?
        let result = sqlite3_exec(db, sql, nil, nil, &errorMessage)
        guard result == SQLITE_OK else {
            let message = errorMessage.map { String(cString: $0) } ?? Self.sqliteMessage(from: db)
            sqlite3_free(errorMessage)
            throw NotesStoreError.sqlite(message: message)
        }
    }

    private func sidecarURL(suffix: String) -> URL {
        URL(fileURLWithPath: databaseURL.path + suffix)
    }

    private func bind(text: String, at index: Int32, in statement: OpaquePointer?) {
        _ = text.withCString { cString in
            sqlite3_bind_text(statement, index, cString, -1, transientDestructor)
        }
    }

    private func closeConnection() {
        if let db {
            sqlite3_close(db)
            self.db = nil
        }
    }

    private static func sqliteMessage(from db: OpaquePointer?) -> String {
        guard let cString = sqlite3_errmsg(db) else {
            return "Unknown SQLite error"
        }
        return String(cString: cString)
    }
}

private let transientDestructor = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
