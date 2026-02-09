//
//  ListContinuationTests.swift
//  GhostlyTests
//
//  Tests for ListContinuation utility.
//

import Testing
@testable import Ghostly

@Suite("ListContinuation Tests")
struct ListContinuationTests {

    @Test("Auto-continue bullet list on Enter")
    func autoContinueBulletList() {
        let previous = "- item one"
        let new = "- item one\n"
        let result = ListContinuation.autoContinueList(newText: new, previousText: previous)
        #expect(result == "- item one\n- ")
    }

    @Test("Auto-continue asterisk bullet list on Enter")
    func autoContinueAsteriskBulletList() {
        let previous = "* item one"
        let new = "* item one\n"
        let result = ListContinuation.autoContinueList(newText: new, previousText: previous)
        #expect(result == "* item one\n* ")
    }

    @Test("Auto-continue unchecked checkbox on Enter")
    func autoContinueUncheckedCheckbox() {
        let previous = "- [ ] task one"
        let new = "- [ ] task one\n"
        let result = ListContinuation.autoContinueList(newText: new, previousText: previous)
        #expect(result == "- [ ] task one\n- [ ] ")
    }

    @Test("Checked checkbox continues as unchecked")
    func checkedCheckboxContinuesAsUnchecked() {
        let previous = "- [x] done task"
        let new = "- [x] done task\n"
        let result = ListContinuation.autoContinueList(newText: new, previousText: previous)
        #expect(result == "- [x] done task\n- [ ] ")
    }

    @Test("Uppercase checked checkbox continues as unchecked")
    func uppercaseCheckedCheckboxContinuesAsUnchecked() {
        let previous = "- [X] done task"
        let new = "- [X] done task\n"
        let result = ListContinuation.autoContinueList(newText: new, previousText: previous)
        #expect(result == "- [X] done task\n- [ ] ")
    }

    @Test("No continuation on non-list lines")
    func noContinuationOnNonListLine() {
        let previous = "regular text"
        let new = "regular text\n"
        let result = ListContinuation.autoContinueList(newText: new, previousText: previous)
        #expect(result == "regular text\n")
    }

    @Test("No continuation on empty list item (double-Enter exits list)")
    func noContinuationOnEmptyListItem() {
        let previous = "- item\n- "
        let new = "- item\n- \n"
        let result = ListContinuation.autoContinueList(newText: new, previousText: previous)
        #expect(result == "- item\n- \n")
    }

    @Test("Auto-continue in middle of document")
    func autoContinueInMiddleOfDocument() {
        let previous = "- first\n- second"
        let new = "- first\n\n- second"
        let result = ListContinuation.autoContinueList(newText: new, previousText: previous)
        #expect(result == "- first\n- \n- second")
    }

    @Test("No change when multiple lines added at once")
    func noChangeWhenMultipleLinesAdded() {
        let previous = "- item"
        let new = "- item\n\n\n"
        let result = ListContinuation.autoContinueList(newText: new, previousText: previous)
        #expect(result == "- item\n\n\n")
    }

    @Test("No change when text is identical")
    func noChangeWhenTextIdentical() {
        let text = "- item"
        let result = ListContinuation.autoContinueList(newText: text, previousText: text)
        #expect(result == "- item")
    }
}
