//
//  GhostlyApp.swift
//  Ghostly
//
//  Created by Ghostly Contributors
//

import SwiftUI

@main
struct GhostlyApp: App {
    var body: some Scene {
        MenuBarExtra("Ghostly", image: "MenubarIcon") {
            ContentView()
                .frame(width: 436, height: 400)
        }
        .menuBarExtraStyle(.window)
    }
}
