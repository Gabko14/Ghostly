//
//  MarkdownTransformerTests.swift
//  GhostlyTests
//
//  Tests for MarkdownTransformer utility.
//

import XCTest
@testable import Ghostly

final class MarkdownTransformerTests: XCTestCase {

    // MARK: - Checkbox Tests

    func testUncheckedCheckboxWithSpace() {
        let input = "[ ] task"
        let expected = "☐ task"
        XCTAssertEqual(MarkdownTransformer.transform(input), expected)
    }

    func testUncheckedCheckboxWithoutSpace() {
        let input = "[] task"
        let expected = "☐ task"
        XCTAssertEqual(MarkdownTransformer.transform(input), expected)
    }

    func testCheckedCheckboxLowercase() {
        let input = "[x] done"
        let expected = "☑ done"
        XCTAssertEqual(MarkdownTransformer.transform(input), expected)
    }

    func testCheckedCheckboxUppercase() {
        let input = "[X] done"
        let expected = "☑ done"
        XCTAssertEqual(MarkdownTransformer.transform(input), expected)
    }

    // MARK: - Bullet Tests

    func testDashBullet() {
        let input = "- item"
        let expected = "• item"
        XCTAssertEqual(MarkdownTransformer.transform(input), expected)
    }

    func testAsteriskBullet() {
        let input = "* item"
        let expected = "• item"
        XCTAssertEqual(MarkdownTransformer.transform(input), expected)
    }

    func testBulletOnlyAtLineStart() {
        let input = "text - not a bullet"
        let expected = "text - not a bullet"
        XCTAssertEqual(MarkdownTransformer.transform(input), expected)
    }

    func testAsteriskOnlyAtLineStart() {
        let input = "text * not a bullet"
        let expected = "text * not a bullet"
        XCTAssertEqual(MarkdownTransformer.transform(input), expected)
    }

    // MARK: - Multiline Tests

    func testMultipleLines() {
        let input = """
            - first item
            - second item
            [ ] unchecked
            [x] checked
            """
        let expected = """
            • first item
            • second item
            ☐ unchecked
            ☑ checked
            """
        XCTAssertEqual(MarkdownTransformer.transform(input), expected)
    }

    func testMixedContent() {
        let input = """
            # Title
            Some text here
            - bullet point
            More text - with dash
            [ ] task to do
            [x] task done
            """
        let expected = """
            # Title
            Some text here
            • bullet point
            More text - with dash
            ☐ task to do
            ☑ task done
            """
        XCTAssertEqual(MarkdownTransformer.transform(input), expected)
    }

    // MARK: - Edge Cases

    func testEmptyString() {
        XCTAssertEqual(MarkdownTransformer.transform(""), "")
    }

    func testNoMarkdown() {
        let input = "Just regular text"
        XCTAssertEqual(MarkdownTransformer.transform(input), input)
    }

    func testAlreadyTransformed() {
        // Should not double-transform
        let input = "☐ task"
        let expected = "☐ task"
        XCTAssertEqual(MarkdownTransformer.transform(input), expected)
    }

    func testBulletAlreadyTransformed() {
        let input = "• item"
        let expected = "• item"
        XCTAssertEqual(MarkdownTransformer.transform(input), expected)
    }

    func testCheckboxWithoutTrailingSpace() {
        // Without trailing space, should not transform
        let input = "[ ]task"
        let expected = "[ ]task"
        XCTAssertEqual(MarkdownTransformer.transform(input), expected)
    }

    func testBulletWithoutTrailingSpace() {
        // Without trailing space, should not transform
        let input = "-item"
        let expected = "-item"
        XCTAssertEqual(MarkdownTransformer.transform(input), expected)
    }

    // MARK: - Bold Text Tests

    func testBoldText() {
        let input = "This is **bold** text"
        let result = MarkdownTransformer.transform(input)
        XCTAssertTrue(result.contains("𝐛𝐨𝐥𝐝"))
        XCTAssertFalse(result.contains("**"))
    }

    func testBoldTextWithNumbers() {
        let input = "**test123**"
        let result = MarkdownTransformer.transform(input)
        XCTAssertTrue(result.contains("𝐭𝐞𝐬𝐭𝟏𝟐𝟑"))
    }

    func testBoldTextPreservesSpaces() {
        let input = "**hello world**"
        let result = MarkdownTransformer.transform(input)
        XCTAssertTrue(result.contains(" "))  // Space preserved
    }

    func testUnmatchedBoldNotTransformed() {
        let input = "This is **not closed"
        XCTAssertEqual(MarkdownTransformer.transform(input), input)
    }

    func testEmptyBoldNotTransformed() {
        let input = "This is **** empty"
        XCTAssertEqual(MarkdownTransformer.transform(input), input)
    }

    func testMultipleBoldSections() {
        let input = "**one** and **two**"
        let result = MarkdownTransformer.transform(input)
        XCTAssertTrue(result.contains("𝐨𝐧𝐞"))
        XCTAssertTrue(result.contains("𝐭𝐰𝐨"))
    }

    // MARK: - Auto-Continue List Tests

    func testAutoContinueBulletList() {
        let previous = "• item one"
        let new = "• item one\n"
        let result = MarkdownTransformer.transform(new, previousText: previous)
        XCTAssertEqual(result, "• item one\n• ")
    }

    func testAutoContinueUncheckedCheckbox() {
        let previous = "☐ task one"
        let new = "☐ task one\n"
        let result = MarkdownTransformer.transform(new, previousText: previous)
        XCTAssertEqual(result, "☐ task one\n☐ ")
    }

    func testAutoContinueCheckedCheckboxCreatesUnchecked() {
        let previous = "☑ done task"
        let new = "☑ done task\n"
        let result = MarkdownTransformer.transform(new, previousText: previous)
        XCTAssertEqual(result, "☑ done task\n☐ ")
    }

    func testNoAutoContinueOnNonListLine() {
        let previous = "regular text"
        let new = "regular text\n"
        let result = MarkdownTransformer.transform(new, previousText: previous)
        XCTAssertEqual(result, "regular text\n")
    }

    func testNoAutoContinueOnEmptyListItem() {
        // If user presses Enter on empty bullet, don't add another
        let previous = "• item\n• "
        let new = "• item\n• \n"
        let result = MarkdownTransformer.transform(new, previousText: previous)
        XCTAssertEqual(result, "• item\n• \n")
    }

    func testAutoContinueInMiddleOfDocument() {
        let previous = "• first\n• second"
        let new = "• first\n\n• second"
        let result = MarkdownTransformer.transform(new, previousText: previous)
        XCTAssertEqual(result, "• first\n• \n• second")
    }
}
