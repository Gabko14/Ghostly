//
//  TabTests.swift
//  GhostlyTests
//
//  Created by Ghostly Contributors
//

import Foundation
import Testing
@testable import Ghostly

// MARK: - GhostlyTab Model Tests

@Suite("GhostlyTab Model Tests")
struct GhostlyTabModelTests {

    @Test("Tab has unique identifier")
    func tabHasUniqueId() {
        let tab1 = GhostlyTab()
        let tab2 = GhostlyTab()
        #expect(tab1.id != tab2.id)
    }

    @Test("Tab initializes with empty content by default")
    func tabDefaultsToEmptyContent() {
        let tab = GhostlyTab()
        #expect(tab.content == "")
    }

    @Test("Tab initializes with provided content")
    func tabInitializesWithContent() {
        let tab = GhostlyTab(content: "Hello world")
        #expect(tab.content == "Hello world")
    }

    @Test("Title returns Untitled for empty content")
    func titleReturnsUntitledForEmpty() {
        let tab = GhostlyTab(content: "")
        #expect(tab.title == "Untitled")
    }

    @Test("Title returns Untitled for whitespace-only content")
    func titleReturnsUntitledForWhitespace() {
        let tab = GhostlyTab(content: "   \n  \t  ")
        #expect(tab.title == "Untitled")
    }

    @Test("Title returns first line when short")
    func titleReturnsFirstLineWhenShort() {
        let tab = GhostlyTab(content: "Short title\nMore content here")
        #expect(tab.title == "Short title")
    }

    @Test("Title truncates to 20 characters with ellipsis")
    func titleTruncatesLongFirstLine() {
        let tab = GhostlyTab(content: "This is a very long first line that should be truncated")
        #expect(tab.title == "This is a very lo...")
        #expect(tab.title.count == 20)
    }

    @Test("Title exactly 20 chars is not truncated")
    func titleExactly20CharsNotTruncated() {
        let tab = GhostlyTab(content: "12345678901234567890") // exactly 20 chars
        #expect(tab.title == "12345678901234567890")
        #expect(tab.title.count == 20)
    }

    @Test("Title trims leading/trailing whitespace from first line")
    func titleTrimsWhitespace() {
        let tab = GhostlyTab(content: "  Hello  \nWorld")
        #expect(tab.title == "Hello")
    }

    @Test("Tab is Codable")
    func tabIsCodable() throws {
        let original = GhostlyTab(content: "Test content")
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GhostlyTab.self, from: encoded)

        #expect(decoded.id == original.id)
        #expect(decoded.content == original.content)
    }

    @Test("Tab is Equatable")
    func tabIsEquatable() {
        let id = UUID()
        let date = Date()
        let tab1 = GhostlyTab(id: id, content: "Test", createdAt: date)
        let tab2 = GhostlyTab(id: id, content: "Test", createdAt: date)

        #expect(tab1 == tab2)
    }
}

// MARK: - TabManager Tests

@Suite("TabManager Tests")
@MainActor
struct TabManagerTests {

    private func freshManager() -> TabManager {
        // Clear any existing data
        UserDefaults.standard.removeObject(forKey: "ghostlyTabs")
        UserDefaults.standard.removeObject(forKey: "ghostlyTabs_activeId")
        UserDefaults.standard.removeObject(forKey: "text")
        return TabManager()
    }

    @Test("Manager initializes with one empty tab")
    func managerInitializesWithOneTab() {
        let manager = freshManager()
        #expect(manager.tabs.count == 1)
        #expect(manager.activeTabId != nil)
        #expect(manager.tabs.first?.content == "")
    }

    @Test("New tab creates and activates a new tab")
    func newTabCreatesAndActivates() {
        let manager = freshManager()
        let initialCount = manager.tabs.count

        let newTab = manager.newTab()

        #expect(manager.tabs.count == initialCount + 1)
        #expect(manager.activeTabId == newTab.id)
    }

    @Test("Close tab removes the specified tab")
    func closeTabRemovesTab() {
        let manager = freshManager()
        let firstTab = manager.tabs[0]
        let _ = manager.newTab()

        #expect(manager.tabs.count == 2)

        manager.closeTab(firstTab.id)

        #expect(manager.tabs.count == 1)
        #expect(!manager.tabs.contains { $0.id == firstTab.id })
    }

    @Test("Closing last tab creates new empty tab")
    func closingLastTabCreatesNew() {
        let manager = freshManager()
        #expect(manager.tabs.count == 1)

        let onlyTab = manager.tabs[0]
        manager.closeTab(onlyTab.id)

        #expect(manager.tabs.count == 1)
        #expect(manager.tabs[0].id != onlyTab.id)
        #expect(manager.tabs[0].content == "")
    }

    @Test("Closing active tab selects adjacent tab")
    func closingActiveTabSelectsAdjacent() {
        let manager = freshManager()
        let tab1 = manager.tabs[0]
        let tab2 = manager.newTab()
        let tab3 = manager.newTab()

        // Active is tab3, close it
        manager.closeTab(tab3.id)
        #expect(manager.activeTabId == tab2.id)

        // Active is tab2, close it
        manager.closeTab(tab2.id)
        #expect(manager.activeTabId == tab1.id)
    }

    @Test("Select tab changes active tab")
    func selectTabChangesActive() {
        let manager = freshManager()
        let tab1 = manager.tabs[0]
        let _ = manager.newTab()

        manager.selectTab(tab1.id)

        #expect(manager.activeTabId == tab1.id)
    }

    @Test("Select nonexistent tab does nothing")
    func selectNonexistentTabDoesNothing() {
        let manager = freshManager()
        let currentActive = manager.activeTabId

        manager.selectTab(UUID())

        #expect(manager.activeTabId == currentActive)
    }

    @Test("Active tab binding reads content")
    func activeTabBindingReadsContent() {
        let manager = freshManager()
        manager.activeTabBinding.wrappedValue = "Hello"

        #expect(manager.activeTabBinding.wrappedValue == "Hello")
    }

    @Test("Active tab binding writes content")
    func activeTabBindingWritesContent() {
        let manager = freshManager()
        manager.activeTabBinding.wrappedValue = "Test content"

        #expect(manager.tabs.first?.content == "Test content")
    }

    @Test("Close active tab convenience method works")
    func closeActiveTabConvenienceMethod() {
        let manager = freshManager()
        let tab1 = manager.tabs[0]
        let _ = manager.newTab()

        #expect(manager.tabs.count == 2)
        #expect(manager.activeTabId != tab1.id)

        manager.closeActiveTab()

        #expect(manager.tabs.count == 1)
        #expect(manager.activeTabId == tab1.id)
    }

    @Test("Active tab property returns correct tab")
    func activeTabPropertyReturnsCorrectTab() {
        let manager = freshManager()
        let activeTab = manager.activeTab

        #expect(activeTab != nil)
        #expect(activeTab?.id == manager.activeTabId)
    }

    @Test("Migrates legacy text storage")
    func migratesLegacyTextStorage() {
        UserDefaults.standard.removeObject(forKey: "ghostlyTabs")
        UserDefaults.standard.removeObject(forKey: "ghostlyTabs_activeId")
        UserDefaults.standard.set("Legacy content", forKey: "text")

        let manager = TabManager()

        #expect(manager.tabs.count == 1)
        #expect(manager.tabs.first?.content == "Legacy content")
        #expect(UserDefaults.standard.string(forKey: "text") == nil)
    }
}
