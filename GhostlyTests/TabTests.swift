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

    // MARK: - Tab Navigation Tests

    @Test("Select tab at valid index changes active tab")
    func selectTabAtValidIndex() {
        let manager = freshManager()
        let tab1 = manager.tabs[0]
        let tab2 = manager.newTab()
        let _ = manager.newTab()

        manager.selectTabAtIndex(0)
        #expect(manager.activeTabId == tab1.id)

        manager.selectTabAtIndex(1)
        #expect(manager.activeTabId == tab2.id)
    }

    @Test("Select tab at invalid index does nothing")
    func selectTabAtInvalidIndex() {
        let manager = freshManager()
        let currentActive = manager.activeTabId

        manager.selectTabAtIndex(-1)
        #expect(manager.activeTabId == currentActive)

        manager.selectTabAtIndex(100)
        #expect(manager.activeTabId == currentActive)
    }

    @Test("Next tab wraps around to first")
    func nextTabWrapsAround() {
        let manager = freshManager()
        let tab1 = manager.tabs[0]
        let tab2 = manager.newTab()
        let tab3 = manager.newTab()

        // Start at tab3 (last created is active)
        #expect(manager.activeTabId == tab3.id)

        manager.selectNextTab()
        #expect(manager.activeTabId == tab1.id)

        manager.selectNextTab()
        #expect(manager.activeTabId == tab2.id)

        manager.selectNextTab()
        #expect(manager.activeTabId == tab3.id)
    }

    @Test("Previous tab wraps around to last")
    func previousTabWrapsAround() {
        let manager = freshManager()
        let tab1 = manager.tabs[0]
        let tab2 = manager.newTab()
        let tab3 = manager.newTab()

        // Start at tab3
        #expect(manager.activeTabId == tab3.id)

        manager.selectPreviousTab()
        #expect(manager.activeTabId == tab2.id)

        manager.selectPreviousTab()
        #expect(manager.activeTabId == tab1.id)

        manager.selectPreviousTab()
        #expect(manager.activeTabId == tab3.id)
    }

    @Test("Next tab does nothing with single tab")
    func nextTabSingleTab() {
        let manager = freshManager()
        let onlyTab = manager.tabs[0]

        manager.selectNextTab()
        #expect(manager.activeTabId == onlyTab.id)
    }

    @Test("Previous tab does nothing with single tab")
    func previousTabSingleTab() {
        let manager = freshManager()
        let onlyTab = manager.tabs[0]

        manager.selectPreviousTab()
        #expect(manager.activeTabId == onlyTab.id)
    }
}

// MARK: - Unicode/CJK Title Truncation Tests (Ghostly-r8t)

@Suite("Unicode Title Truncation Tests")
struct UnicodeTitleTruncationTests {

    @Test("Latin text truncation preserves existing behavior")
    func latinTextTruncation() {
        let tab = GhostlyTab(content: "This is a very long first line that should be truncated")
        #expect(tab.title == "This is a very lo...")
        #expect(tab.title.count == 20)
    }

    @Test("Latin text exactly at 20 visual width is not truncated")
    func latinExactly20NotTruncated() {
        let tab = GhostlyTab(content: "12345678901234567890") // 20 Latin chars = 20 visual width
        #expect(tab.title == "12345678901234567890")
    }

    @Test("CJK text truncates sooner due to double visual width")
    func cjkTextTruncatesSooner() {
        // 13 CJK/Katakana chars = 26 visual width > 20, should truncate
        // Target width = 17. 8 CJK chars = 16 visual (fits), 9th = 18 (exceeds)
        let tab = GhostlyTab(content: "日本語のテストテキストです")
        #expect(tab.title.hasSuffix("..."))
        #expect(tab.title == "日本語のテストテ...")
    }

    @Test("CJK text at exactly 20 visual width is not truncated")
    func cjkExactly20VisualWidth() {
        // 10 CJK chars = 20 visual width exactly, should NOT truncate
        let tab = GhostlyTab(content: "日本語テストテキス九")
        #expect(!tab.title.hasSuffix("..."))
        #expect(tab.title == "日本語テストテキス九")
    }

    @Test("Mixed Latin and CJK text truncates by visual width")
    func mixedLatinCjkTruncation() {
        // "Hello" (5) + CJK chars (2 each) = 25 visual > 20
        // Target = 17: "Hello"(5) + 6 CJK(12) = 17, next CJK would exceed
        let tab = GhostlyTab(content: "Hello日本語テストテキスト")
        #expect(tab.title.hasSuffix("..."))
        #expect(tab.title == "Hello日本語テスト...")
    }

    @Test("Korean Hangul text truncates at correct visual width")
    func koreanHangulTruncation() {
        // 11 Hangul chars = 22 visual width > 20
        // 8 Hangul = 16 visual (fits target 17), 9th = 18 (exceeds)
        let tab = GhostlyTab(content: "안녕하세요테스트입니다")
        #expect(tab.title.hasSuffix("..."))
        #expect(tab.title == "안녕하세요테스트...")
    }

    @Test("Emoji with ZWJ sequences handled correctly")
    func emojiZwjSequences() {
        // Short text with ZWJ emoji should not truncate
        let shortEmoji = GhostlyTab(content: "Hi 👨‍👩‍👧‍👦 there")
        #expect(!shortEmoji.title.hasSuffix("..."))

        // Long text with emoji should truncate
        let longEmoji = GhostlyTab(content: "Hello 👨‍👩‍👧‍👦 World Test Content Here Extra More")
        #expect(longEmoji.title.hasSuffix("..."))
    }

    @Test("Fullwidth Latin characters count as double width")
    func fullwidthLatinChars() {
        // 11 fullwidth chars = 22 visual > 20
        // 8 fullwidth = 16 visual (fits target 17), 9th = 18 (exceeds)
        let tab = GhostlyTab(content: "ＡＢＣＤＥＦＧＨＩＪＫ")
        #expect(tab.title.hasSuffix("..."))
        #expect(tab.title == "ＡＢＣＤＥＦＧＨ...")
    }

    @Test("Japanese Hiragana counts as double width")
    func japaneseHiraganaTruncation() {
        // 11 hiragana = 22 visual > 20
        let tab = GhostlyTab(content: "あいうえおかきくけこさ")
        #expect(tab.title.hasSuffix("..."))
        #expect(tab.title == "あいうえおかきく...")
    }

    @Test("Empty and Untitled behavior unchanged with Unicode fix")
    func emptyAndUntitled() {
        let emptyTab = GhostlyTab(content: "")
        #expect(emptyTab.title == "Untitled")

        let whitespaceTab = GhostlyTab(content: "   ")
        #expect(whitespaceTab.title == "Untitled")
    }
}
