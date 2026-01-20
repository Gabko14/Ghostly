//
//  DropdownMenuView.swift
//  Ghostly
//
//  Created by Jay Stakelon on 1/30/21.
//

import SwiftUI

struct DropdownMenuView: View {
    var settingsManager: SettingsManager
    @State private var isHovered = false

    var body: some View {
        Menu {
            Button("Settings...") {
                settingsManager.toggleSettings()
            }
            .keyboardShortcut(",")
            .accessibilityIdentifier("settingsButton")

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isHovered ? Color.catText : Color.catLavender)
                .brightness(isHovered ? 0.05 : 0)
                .animation(.easeOut(duration: 0.15), value: isHovered)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
