//
//  AppStateTests.swift
//  GhostlyTests
//
//  Created by Ghostly Contributors
//

import Testing
@testable import Ghostly

@Suite("AppState Tests")
@MainActor
struct AppStateTests {

    @Test("Initial state has menu not presented")
    func initialStateHasMenuNotPresented() {
        let appState = AppState()
        #expect(appState.isMenuPresented == false)
    }

    @Test("Menu presented state can be toggled")
    func menuPresentedStateCanBeToggled() {
        let appState = AppState()

        #expect(appState.isMenuPresented == false)

        appState.isMenuPresented.toggle()
        #expect(appState.isMenuPresented == true)

        appState.isMenuPresented.toggle()
        #expect(appState.isMenuPresented == false)
    }

    @Test("Menu presented state can be set directly")
    func menuPresentedStateCanBeSetDirectly() {
        let appState = AppState()

        appState.isMenuPresented = true
        #expect(appState.isMenuPresented == true)

        appState.isMenuPresented = false
        #expect(appState.isMenuPresented == false)
    }
}
