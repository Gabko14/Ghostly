//
//  PersistenceCoordinator.swift
//  Ghostly
//

import Foundation
import OSLog

@MainActor
final class PersistenceCoordinator {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.ghostly.Ghostly",
        category: "PersistenceCoordinator"
    )

    private let notesStore: NotesStore
    private let tabManager: TabManager
    private let autosaveDelay: Duration
    private let backupInterval: Duration
    private let terminationTimeout: Duration

    private var autosaveTask: Task<Void, Never>?
    private var currentFlushTask: Task<Void, Never>?
    private var isReady = false
    private var isFlushing = false
    private var pendingFlushReason: FlushReason?
    private var lastBackupAt: Date?

    init(
        notesStore: NotesStore,
        tabManager: TabManager,
        autosaveDelay: Duration = .milliseconds(250),
        backupInterval: Duration = .seconds(30),
        terminationTimeout: Duration = .seconds(2)
    ) {
        self.notesStore = notesStore
        self.tabManager = tabManager
        self.autosaveDelay = autosaveDelay
        self.backupInterval = backupInterval
        self.terminationTimeout = terminationTimeout
    }

    deinit {
        autosaveTask?.cancel()
        currentFlushTask?.cancel()
    }

    func setReady(_ isReady: Bool) {
        self.isReady = isReady
    }

    func scheduleAutosave() {
        guard isReady else { return }

        autosaveTask?.cancel()
        let autosaveDelay = self.autosaveDelay
        autosaveTask = Task { [weak self, autosaveDelay] in
            try? await Task.sleep(for: autosaveDelay)
            guard !Task.isCancelled else { return }
            await self?.flushNow(reason: .typingIdle)
        }
    }

    func flushNow(reason: FlushReason) async {
        guard isReady else { return }
        autosaveTask?.cancel()

        guard tabManager.hasDirtyChanges else { return }
        if isFlushing {
            enqueuePendingFlush(reason)
            await currentFlushTask?.value
            return
        }

        let flushTask = Task { @MainActor [weak self] in
            guard let self else { return }

            self.isFlushing = true
            defer {
                self.isFlushing = false
                self.currentFlushTask = nil
            }

            var currentReason: FlushReason? = reason
            while let reason = currentReason {
                self.pendingFlushReason = nil
                let changeSet = self.tabManager.currentChangeSet()
                guard changeSet.hasChanges else {
                    currentReason = self.pendingFlushReason
                    continue
                }

                do {
                    let shouldWriteBackup = self.shouldWriteBackup(for: reason)
                    try await self.notesStore.save(changeSet, writeBackup: shouldWriteBackup)
                    try await self.notesStore.flush()
                    self.tabManager.markPersisted(changeSet)
                    if shouldWriteBackup {
                        self.lastBackupAt = Date()
                    }
                } catch {
                    self.logger.error("Failed to flush notes for \(reason.rawValue, privacy: .public): \(error.localizedDescription, privacy: .public)")
                    return
                }

                currentReason = self.pendingFlushReason ?? (self.tabManager.hasDirtyChanges ? .typingIdle : nil)
            }
        }

        currentFlushTask = flushTask
        await flushTask.value
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
                try? await Task.sleep(for: self.terminationTimeout)
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

    private func enqueuePendingFlush(_ reason: FlushReason) {
        guard let pendingFlushReason else {
            self.pendingFlushReason = reason
            return
        }

        self.pendingFlushReason = pendingFlushReason.priority >= reason.priority ? pendingFlushReason : reason
    }
}

private extension Duration {
    var timeInterval: TimeInterval {
        TimeInterval(components.seconds) + (TimeInterval(components.attoseconds) / 1_000_000_000_000_000_000)
    }
}

private extension FlushReason {
    var priority: Int {
        switch self {
        case .typingIdle:
            return 0
        case .tabSwitch:
            return 1
        case .tabCreated:
            return 2
        case .tabClosed:
            return 3
        case .popoverClosed:
            return 4
        case .appResignedActive:
            return 5
        case .manualRecoveryAction:
            return 6
        case .appTermination:
            return 7
        }
    }
}
