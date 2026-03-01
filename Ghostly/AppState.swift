//
//  AppState.swift
//  Ghostly
//
//  Created by Ghostly Contributors
//

import SwiftUI
import AppKit
import KeyboardShortcuts

@MainActor
@Observable
final class AppState {
    var isMenuPresented: Bool = false {
        didSet {
            updateTabShortcuts(enabled: isMenuPresented)
            if oldValue, !isMenuPresented {
                Task { await persistenceCoordinator.popoverDidClose() }
            }
        }
    }
    let settingsManager: SettingsManager
    let notesStore: NotesStore
    let tabManager: TabManager
    let persistenceCoordinator: PersistenceCoordinator

    var launchState: LaunchState = .loading
    var recoveryNotice: String = ""

    var isSettingsOpen: Bool {
        get { settingsManager.isSettingsOpen }
        set { settingsManager.isSettingsOpen = newValue }
    }

    init(
        notesStore: NotesStore = NotesStore(),
        settingsManager: SettingsManager = SettingsManager(),
        registerKeyboardShortcuts: Bool = true,
        autoStart: Bool = true
    ) {
        self.notesStore = notesStore
        self.settingsManager = settingsManager
        self.tabManager = TabManager()
        self.persistenceCoordinator = PersistenceCoordinator(
            notesStore: notesStore,
            tabManager: tabManager
        )

        tabManager.onPersistenceTrigger = { [weak self] trigger in
            guard let self else { return }
            switch trigger {
            case .scheduleAutosave:
                self.persistenceCoordinator.scheduleAutosave()
            case let .flush(reason):
                Task { await self.persistenceCoordinator.flushNow(reason: reason) }
            }
        }

        if registerKeyboardShortcuts {
            registerShortcuts()
            updateTabShortcuts(enabled: false)
        }

        if autoStart {
            Task { await start() }
        }
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

    private func registerShortcuts() {
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
    }

    private func updateTabShortcuts(enabled: Bool) {
        for shortcut in Self.tabShortcuts {
            if enabled {
                KeyboardShortcuts.enable(shortcut)
            } else {
                KeyboardShortcuts.disable(shortcut)
            }
        }
    }

    func start() async {
        launchState = .loading
        recoveryNotice = ""
        persistenceCoordinator.setReady(false)

        do {
            try await notesStore.open()
            _ = try await notesStore.migrateLegacyUserDefaultsIfNeeded()
            let snapshot = try await notesStore.loadSnapshot()
            tabManager.load(snapshot: snapshot)
            launchState = .ready
            persistenceCoordinator.setReady(true)
        } catch {
            launchState = await buildRecoveryState(for: error)
        }
    }

    func restoreFromLatestBackup() async {
        recoveryNotice = ""
        launchState = .recovery(.restoreInProgress)
        do {
            let snapshot = try await notesStore.restoreFromLatestBackup()
            tabManager.load(snapshot: snapshot)
            launchState = .ready
            persistenceCoordinator.setReady(true)
        } catch {
            launchState = await buildRecoveryState(for: error)
        }
    }

    func startFresh() async {
        recoveryNotice = ""
        do {
            let snapshot = try await notesStore.createFreshStore()
            tabManager.load(snapshot: snapshot)
            launchState = .ready
            persistenceCoordinator.setReady(true)
        } catch {
            launchState = await buildRecoveryState(for: error)
        }
    }

    func exportRecoveryBundle() async {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Export"
        panel.message = "Choose a folder for the Ghostly recovery bundle."

        guard panel.runModal() == .OK, let destinationURL = panel.url else { return }

        do {
            try await notesStore.exportRecoveryBundle(to: destinationURL)
            recoveryNotice = "Recovery bundle exported to \(destinationURL.path)"
        } catch {
            recoveryNotice = error.localizedDescription
        }
    }

    private func buildRecoveryState(for error: Error) async -> LaunchState {
        persistenceCoordinator.setReady(false)

        if case .migrationFailed = error as? NotesStoreError {
            let backupURL = await notesStore.lastMigrationBackupIfAvailable()
            return .recovery(
                .migrationFailed(
                    summary: error.localizedDescription,
                    legacyBackupURL: backupURL
                )
            )
        }

        let quarantineURL = (try? await notesStore.quarantineCurrentStore(reason: error.localizedDescription))
            ?? URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Ghostly-quarantine-unavailable", isDirectory: true)
        let backupURL = await notesStore.latestBackupIfAvailable()
        return .recovery(
            .storeUnreadable(
                summary: error.localizedDescription,
                quarantineURL: quarantineURL,
                backupURL: backupURL
            )
        )
    }
}
