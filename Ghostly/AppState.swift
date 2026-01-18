//
//  AppState.swift
//  Ghostly
//
//  Created by Ghostly Contributors
//

import SwiftUI
import KeyboardShortcuts

@MainActor
@Observable
final class AppState {
    var isMenuPresented: Bool = false

    init() {
        KeyboardShortcuts.onKeyUp(for: .toggleGhostly) { [weak self] in
            Task { @MainActor in
                self?.isMenuPresented.toggle()
            }
        }
    }
}
