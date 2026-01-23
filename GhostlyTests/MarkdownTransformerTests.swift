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
}
