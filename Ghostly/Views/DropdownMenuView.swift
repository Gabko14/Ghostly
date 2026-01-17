//
//  DropdownMenuView.swift
//  Ghostly
//
//  Created by Jay Stakelon on 1/30/21.
//

import SwiftUI

struct DropdownMenuView: View {
    @ObservedObject var themeManager: ThemeManager

    var body: some View {
        Menu {
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
