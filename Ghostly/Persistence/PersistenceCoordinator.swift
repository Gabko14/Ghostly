//
//  PersistenceCoordinator.swift
//  Ghostly
//

import Foundation
import OSLog

@MainActor
final class PersistenceCoordinator {
    static var shared: PersistenceCoordinator?

    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.ghostly.Ghostly",
        category: "PersistenceCoordinator"
    )

    private let notesStore: NotesStore
    private unowned let tabManager: TabManager
    private let autosaveDelay: Duration
    private let backupInterval: Duration

    private var autosaveTask: Task<Void, Never>?
    private var isReady = false
    private var isFlushing = false
    private var pendingFlushReason: FlushReason?
    private var lastBackupAt: Date?

    init(
        notesStore: NotesStore,
        tabManager: TabManager,
        autosaveDelay: Duration = .milliseconds(250),
        backupInterval: Duration = .seconds(30)
    ) {
        self.notesStore = notesStore
        self.tabManager = tabManager
        self.autosaveDelay = autosaveDelay
        self.backupInterval = backupInterval
        Self.shared = self
    }

    func setReady(_ isReady: Bool) {
        self.isReady = isReady
    }

    func scheduleAutosave() {
        guard isReady else { return }

        autosaveTask?.cancel()
        autosaveTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: self.autosaveDelay)
            guard !Task.isCancelled else { return }
            await self.flushNow(reason: .typingIdle)
        }
    }

    func flushNow(reason: FlushReason) async {
        guard isReady else { return }
        autosaveTask?.cancel()

        guard tabManager.hasDirtyChanges else { return }
        if isFlushing {
            pendingFlushReason = reason
            return
        }

        isFlushing = true
        defer { isFlushing = false }

        var currentReason: FlushReason? = reason
        while let reason = currentReason {
            pendingFlushReason = nil
            let changeSet = tabManager.currentChangeSet()
            guard changeSet.hasChanges else {
                currentReason = pendingFlushReason
                continue
            }

            do {
                let shouldWriteBackup = shouldWriteBackup(for: reason)
                try await notesStore.save(changeSet, writeBackup: shouldWriteBackup)
                try await notesStore.flush()
                tabManager.markPersisted(changeSet)
                if shouldWriteBackup {
                    lastBackupAt = Date()
                }
            } catch {
                logger.error("Failed to flush notes for \(reason.rawValue, privacy: .public): \(error.localizedDescription, privacy: .public)")
                return
            }

            currentReason = pendingFlushReason ?? (tabManager.hasDirtyChanges ? .typingIdle : nil)
        }
    }

    func popoverDidClose() async {
        await flushNow(reason: .popoverClosed)
    }

    func appDidResignActive() async {
        await flushNow(reason: .appResignedActive)
    }

    func handleTerminationRequest() async -> Bool {
        guard isReady else { return true }

        return await withTaskGroup(of: Bool.self) { group in
            group.addTask { [weak self] in
                guard let self else { return true }
                await self.flushNow(reason: .appTermination)
                return true
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(2))
                return true
            }
            let result = await group.next() ?? true
            group.cancelAll()
            return result
        }
    }

    private func shouldWriteBackup(for reason: FlushReason) -> Bool {
        switch reason {
        case .typingIdle:
            guard let lastBackupAt else { return true }
            return Date().timeIntervalSince(lastBackupAt) >= backupInterval.timeInterval
        case .tabSwitch, .tabCreated, .tabClosed, .popoverClosed, .appResignedActive, .appTermination, .manualRecoveryAction:
            return true
        }
    }
}

private extension Duration {
    var timeInterval: TimeInterval {
        TimeInterval(components.seconds) + (TimeInterval(components.attoseconds) / 1_000_000_000_000_000_000)
    }
}
