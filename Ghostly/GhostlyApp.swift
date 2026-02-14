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

    private lazy var contextMenu: NSMenu = {
        let menu = NSMenu()

        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit Ghostly",
            action: #selector(quitGhostly),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }()

    func configure(statusItem: NSStatusItem, appState: AppState) {
        self.statusItem = statusItem
        self.appState = appState

        statusItem.button?.target = self
        statusItem.button?.action = #selector(handleStatusItemClick)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc
    private func handleStatusItemClick() {
        guard let event = NSApp.currentEvent else { return }

        let isRightClick = event.type == .rightMouseUp
            || (event.type == .leftMouseUp && event.modifierFlags.contains(.control))

        if isRightClick {
            presentContextMenu(with: event)
        } else {
            appState?.isMenuPresented.toggle()
        }
    }

    private func presentContextMenu(with event: NSEvent) {
        guard let button = statusItem?.button else { return }
        appState?.isMenuPresented = false
        NSMenu.popUpContextMenu(contextMenu, with: event, for: button)
    }

    @objc
    private func openSettings() {
        appState?.isSettingsOpen = true
        appState?.isMenuPresented = true
    }

    @objc
    private func quitGhostly() {
        NSApplication.shared.terminate(nil)
    }
}
