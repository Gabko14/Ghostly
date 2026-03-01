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

    private struct LegacyTabPayload: Codable {
        let id: UUID
        let content: String
        let createdAt: Date
    }

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

    @Test("Legacy decoding defaults updatedAt to createdAt")
    func legacyDecodingDefaultsUpdatedAt() throws {
        let payload = LegacyTabPayload(
            id: UUID(),
            content: "Legacy content",
            createdAt: Date(timeIntervalSince1970: 123)
        )

        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(GhostlyTab.self, from: data)

        #expect(decoded.createdAt == payload.createdAt)
        #expect(decoded.updatedAt == payload.createdAt)
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
        let tab = GhostlyTab(content: "12345678901234567890")
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
        #expect(decoded.updatedAt == original.updatedAt)
    }

    @Test("Tab is Equatable")
    func tabIsEquatable() {
        let id = UUID()
        let date = Date()
        let tab1 = GhostlyTab(id: id, content: "Test", createdAt: date, updatedAt: date)
        let tab2 = GhostlyTab(id: id, content: "Test", createdAt: date, updatedAt: date)

        #expect(tab1 == tab2)
    }
}

// MARK: - TabManager Tests

@Suite("TabManager Tests")
@MainActor
struct TabManagerTests {

    private func freshManager() -> TabManager {
        TabManager()
    }

    @Test("Manager initializes with one empty tab")
    func managerInitializesWithOneTab() {
        let manager = freshManager()

        #expect(manager.tabs.count == 1)
        #expect(manager.activeTabId == manager.tabs.first?.id)
        #expect(manager.tabs.first?.content == "")
        #expect(!manager.hasDirtyChanges)
    }

    @Test("New tab creates and activates a new tab")
    func newTabCreatesAndActivates() {
        let manager = freshManager()
        var flushReasons: [FlushReason] = []
        manager.onPersistenceTrigger = { trigger in
            if case let .flush(reason) = trigger {
                flushReasons.append(reason)
            }
        }

        let newTab = manager.newTab()

        #expect(manager.tabs.count == 2)
        #expect(manager.activeTabId == newTab.id)
        #expect(manager.hasDirtyChanges)
        #expect(flushReasons == [.tabCreated])
    }

    @Test("Closing a tab reindexes remaining tabs for persistence")
    func closingTabReindexesRemainingTabs() {
        let manager = freshManager()
        let firstTab = manager.tabs[0]
        let middleTab = manager.newTab()
        let lastTab = manager.newTab()
        manager.markPersisted(manager.currentChangeSet())

        var flushReasons: [FlushReason] = []
        manager.onPersistenceTrigger = { trigger in
            if case let .flush(reason) = trigger {
                flushReasons.append(reason)
            }
        }

        manager.closeTab(middleTab.id)
        let changeSet = manager.currentChangeSet()

        #expect(manager.tabs.map(\.id) == [firstTab.id, lastTab.id])
        #expect(Set(changeSet.deletedTabIDs) == [middleTab.id])
        #expect(changeSet.upsertedTabs.map(\.id) == [firstTab.id, lastTab.id])
        #expect(changeSet.upsertedTabs.map(\.sortIndex) == [0, 1])
        #expect(flushReasons == [.tabClosed])
    }

    @Test("Closing last tab creates a fresh empty replacement")
    func closingLastTabCreatesNew() {
        let manager = freshManager()
        let onlyTab = manager.tabs[0]

        manager.closeTab(onlyTab.id)

        #expect(manager.tabs.count == 1)
        #expect(manager.tabs[0].id != onlyTab.id)
        #expect(manager.tabs[0].content == "")
        #expect(manager.activeTabId == manager.tabs[0].id)
    }

    @Test("Selecting tab changes active tab and requests flush")
    func selectTabChangesActive() {
        let manager = freshManager()
        let firstTab = manager.tabs[0]
        _ = manager.newTab()
        manager.markPersisted(manager.currentChangeSet())

        var flushReasons: [FlushReason] = []
        manager.onPersistenceTrigger = { trigger in
            if case let .flush(reason) = trigger {
                flushReasons.append(reason)
            }
        }

        manager.selectTab(firstTab.id)

        #expect(manager.activeTabId == firstTab.id)
        #expect(flushReasons == [.tabSwitch])
        #expect(manager.currentChangeSet().metadataRevision != nil)
    }

    @Test("Active tab binding writes content and schedules autosave")
    func activeTabBindingWritesContent() {
        let manager = freshManager()
        var autosaveRequests = 0
        manager.onPersistenceTrigger = { trigger in
            if case .scheduleAutosave = trigger {
                autosaveRequests += 1
            }
        }

        manager.activeTabBinding.wrappedValue = "Test content"
        let changeSet = manager.currentChangeSet()

        #expect(manager.tabs.first?.content == "Test content")
        #expect(changeSet.upsertedTabs.count == 1)
        #expect(changeSet.upsertedTabs.first?.content == "Test content")
        #expect(autosaveRequests == 1)
    }

    @Test("No-op edit does not schedule autosave")
    func noOpEditDoesNotScheduleAutosave() {
        let manager = freshManager()
        var autosaveRequests = 0
        manager.onPersistenceTrigger = { trigger in
            if case .scheduleAutosave = trigger {
                autosaveRequests += 1
            }
        }

        manager.activeTabBinding.wrappedValue = ""

        #expect(!manager.hasDirtyChanges)
        #expect(autosaveRequests == 0)
    }

    @Test("Loading snapshot hydrates manager and clears dirty state")
    func loadingSnapshotHydratesAndClearsDirtyState() {
        let manager = freshManager()
        manager.activeTabBinding.wrappedValue = "Dirty content"

        let first = PersistedTab(
            id: UUID(),
            content: "First",
            createdAt: Date(timeIntervalSince1970: 1),
            updatedAt: Date(timeIntervalSince1970: 2),
            sortIndex: 0
        )
        let second = PersistedTab(
            id: UUID(),
            content: "Second",
            createdAt: Date(timeIntervalSince1970: 3),
            updatedAt: Date(timeIntervalSince1970: 4),
            sortIndex: 1
        )

        manager.load(snapshot: NotesSnapshot(tabs: [first, second], activeTabID: second.id))

        #expect(manager.tabs.map(\.id) == [first.id, second.id])
        #expect(manager.activeTabId == second.id)
        #expect(manager.activeTabBinding.wrappedValue == "Second")
        #expect(!manager.hasDirtyChanges)
    }

    @Test("Mark persisted ignores stale revisions")
    func markPersistedIgnoresStaleRevisions() {
        let manager = freshManager()

        manager.activeTabBinding.wrappedValue = "First edit"
        let staleChangeSet = manager.currentChangeSet()
        manager.activeTabBinding.wrappedValue = "Second edit"

        manager.markPersisted(staleChangeSet)

        #expect(manager.hasDirtyChanges)
        #expect(manager.currentChangeSet().upsertedTabs.first?.content == "Second edit")
    }

    @Test("Current snapshot reflects tab order and active tab")
    func currentSnapshotReflectsOrderAndActiveTab() {
        let manager = freshManager()
        manager.activeTabBinding.wrappedValue = "First"
        let secondTab = manager.newTab()
        manager.activeTabBinding.wrappedValue = "Second"

        let snapshot = manager.currentSnapshot()

        #expect(snapshot.tabs.map(\.sortIndex) == [0, 1])
        #expect(snapshot.tabs.map(\.content) == ["First", "Second"])
        #expect(snapshot.activeTabID == secondTab.id)
    }

    @Test("Tab navigation wraps across tabs")
    func tabNavigationWraps() {
        let manager = freshManager()
        let firstTab = manager.tabs[0]
        let secondTab = manager.newTab()
        let thirdTab = manager.newTab()

        #expect(manager.activeTabId == thirdTab.id)

        manager.selectNextTab()
        #expect(manager.activeTabId == firstTab.id)

        manager.selectPreviousTab()
        #expect(manager.activeTabId == thirdTab.id)

        manager.selectTab(secondTab.id)
        #expect(manager.activeTabId == secondTab.id)
    }
}

// MARK: - Unicode/CJK Title Truncation Tests

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
        let tab = GhostlyTab(content: "12345678901234567890")
        #expect(tab.title == "12345678901234567890")
    }

    @Test("CJK text truncates sooner due to double visual width")
    func cjkTextTruncatesSooner() {
        let tab = GhostlyTab(content: "日本語のテストテキストです")
        #expect(tab.title.hasSuffix("..."))
        #expect(tab.title == "日本語のテストテ...")
    }

    @Test("CJK text at exactly 20 visual width is not truncated")
    func cjkExactly20VisualWidth() {
        let tab = GhostlyTab(content: "日本語テストテキス九")
        #expect(!tab.title.hasSuffix("..."))
        #expect(tab.title == "日本語テストテキス九")
    }

    @Test("Mixed Latin and CJK text truncates by visual width")
    func mixedLatinCjkTruncation() {
        let tab = GhostlyTab(content: "Hello日本語テストテキスト")
        #expect(tab.title.hasSuffix("..."))
        #expect(tab.title == "Hello日本語テスト...")
    }

    @Test("Korean Hangul text truncates at correct visual width")
    func koreanHangulTruncation() {
        let tab = GhostlyTab(content: "안녕하세요테스트입니다")
        #expect(tab.title.hasSuffix("..."))
        #expect(tab.title == "안녕하세요테스트...")
    }

    @Test("Emoji with ZWJ sequences handled correctly")
    func emojiZwjSequences() {
        let shortEmoji = GhostlyTab(content: "Hi 👨‍👩‍👧‍👦 there")
        #expect(!shortEmoji.title.hasSuffix("..."))

        let longEmoji = GhostlyTab(content: "Hello 👨‍👩‍👧‍👦 World Test Content Here Extra More")
        #expect(longEmoji.title.hasSuffix("..."))
    }

    @Test("Fullwidth Latin characters count as double width")
    func fullwidthLatinChars() {
        let tab = GhostlyTab(content: "ＡＢＣＤＥＦＧＨＩＪＫ")
        #expect(tab.title.hasSuffix("..."))
        #expect(tab.title == "ＡＢＣＤＥＦＧＨ...")
    }

    @Test("Japanese Hiragana counts as double width")
    func japaneseHiraganaTruncation() {
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
