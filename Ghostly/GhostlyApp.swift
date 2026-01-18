//
//  GhostlyApp.swift
//  Ghostly
//
//  Created by Ghostly Contributors
//

import SwiftUI
import MenuBarExtraAccess

@main
struct GhostlyApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("Ghostly", image: "MenubarIcon") {
            ContentView()
                .frame(width: 436, height: 400)
        }
        .menuBarExtraStyle(.window)
        .menuBarExtraAccess(isPresented: $appState.isMenuPresented)
    }
}
