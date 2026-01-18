//
//  DropdownMenuView.swift
//  Ghostly
//
//  Created by Jay Stakelon on 1/30/21.
//

import SwiftUI

struct DropdownMenuView: View {
    var settingsManager: SettingsManager

    var body: some View {
        Menu {
            Button("Settings...") {
                settingsManager.showSettings()
            }
            .keyboardShortcut(",")
            .accessibilityIdentifier("settingsButton")

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 14))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
    }
}
