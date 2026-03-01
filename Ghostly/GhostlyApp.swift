//
//  GhostlyApp.swift
//  Ghostly
//
//  Created by Ghostly Contributors
//

import SwiftUI
import AppKit
import MenuBarExtraAccess

@main
struct GhostlyApp: App {
    @NSApplicationDelegateAdaptor(AppLifecycleDelegate.self) private var appLifecycleDelegate
    @State private var appState: AppState
    @State private var statusItemContextMenuController = StatusItemContextMenuController()

    init() {
        let appState = AppState()
        _appState = State(initialValue: appState)
        appLifecycleDelegate.persistenceCoordinator = appState.persistenceCoordinator
    }

    var body: some Scene {
        MenuBarExtra("Ghostly", image: "MenubarIcon") {
            Group {
                switch appState.launchState {
                case .loading:
                    ProgressView("Loading notes...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .ready:
                    ContentView(appState: appState)
                case let .recovery(recoveryState):
                    RecoveryView(appState: appState, recoveryState: recoveryState)
                }
            }
            .frame(width: 436, height: 400)
            .background(.clear)
        }
        .menuBarExtraStyle(.window)
        .menuBarExtraAccess(isPresented: $appState.isMenuPresented) { statusItem in
            statusItemContextMenuController.configure(statusItem: statusItem, appState: appState)
        }
    }
}

@MainActor
final class StatusItemContextMenuController: NSObject {
    private weak var appState: AppState?
    private weak var statusItem: NSStatusItem?
    private var localMouseMonitor: Any?

    private lazy var contextMenu: NSMenu = {
        let menu = NSMenu()

        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ""
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit Ghostly",
            action: #selector(quitGhostly),
            keyEquivalent: ""
        )
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }()

    func configure(statusItem: NSStatusItem, appState: AppState) {
        self.appState = appState
        self.statusItem = statusItem
        installLocalMonitorIfNeeded()
    }

    private func installLocalMonitorIfNeeded() {
        guard localMouseMonitor == nil else { return }

        localMouseMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.rightMouseDown, .leftMouseDown]
        ) { [weak self] event in
            guard let self else { return event }
            return self.handleMouseEvent(event)
        }
    }

    private func handleMouseEvent(_ event: NSEvent) -> NSEvent? {
        guard let statusButton = statusItem?.button,
              let eventWindow = event.window,
              eventWindow == statusButton.window else {
            return event
        }

        let isSecondaryClick = event.type == .rightMouseDown
            || (event.type == .leftMouseDown && event.modifierFlags.contains(.control))

        guard isSecondaryClick else {
            return event
        }

        let pointInButton = statusButton.convert(event.locationInWindow, from: nil)
        guard statusButton.bounds.contains(pointInButton) else {
            return event
        }

        presentContextMenu(using: event, statusButton: statusButton)
        return nil
    }

    private func presentContextMenu(using event: NSEvent, statusButton: NSStatusBarButton) {
        appState?.isMenuPresented = false
        NSMenu.popUpContextMenu(contextMenu, with: event, for: statusButton)
    }

    @objc
    private func openSettings() {
        appState?.isMenuPresented = true
        Task { @MainActor [weak self] in
            self?.appState?.isSettingsOpen = true
        }
    }

    @objc
    private func quitGhostly() {
        NSApplication.shared.terminate(nil)
    }
}
