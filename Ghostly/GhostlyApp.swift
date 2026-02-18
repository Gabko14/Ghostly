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
    @State private var appState = AppState()
    @State private var statusItemContextMenuController = StatusItemContextMenuController()

    var body: some Scene {
        MenuBarExtra("Ghostly", image: "MenubarIcon") {
            ContentView(appState: appState)
                .frame(width: 436, height: 400)
                .background(.clear)
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                    appState.tabManager.flushPendingSave()
                }
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

        let updateItem = NSMenuItem(
            title: "Check for Updates...",
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        updateItem.target = self
        menu.addItem(updateItem)

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
        DispatchQueue.main.async { [weak self] in
            self?.appState?.isSettingsOpen = true
        }
    }

    @objc
    private func checkForUpdates() {
        appState?.updaterManager.checkForUpdates()
    }

    @objc
    private func quitGhostly() {
        NSApplication.shared.terminate(nil)
    }
}
