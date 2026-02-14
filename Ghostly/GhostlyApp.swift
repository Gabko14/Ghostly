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
    private weak var statusButton: NSStatusBarButton?
    private var rightClickGestureRecognizer: NSClickGestureRecognizer?

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

        guard let button = statusItem.button else { return }

        if self.statusButton === button {
            return
        }

        if let previousButton = self.statusButton,
           let previousRecognizer = rightClickGestureRecognizer {
            previousButton.removeGestureRecognizer(previousRecognizer)
        }

        let recognizer = NSClickGestureRecognizer(target: self, action: #selector(handleRightClick))
        recognizer.buttonMask = 0x2
        button.addGestureRecognizer(recognizer)

        self.statusButton = button
        self.rightClickGestureRecognizer = recognizer
    }

    @objc
    private func handleRightClick() {
        guard let statusButton,
              let event = NSApp.currentEvent else {
            return
        }
        appState?.isMenuPresented = false
        NSMenu.popUpContextMenu(contextMenu, with: event, for: statusButton)
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
