//
//  TextManagerTests.swift
//  NotebarTests
//
//  Created by Ghostly Contributors
//

import XCTest
@testable import Notebar

final class TextManagerTests: XCTestCase {

    override func setUpWithError() throws {
        UserDefaults.standard.removeObject(forKey: "text")
    }

    override func tearDownWithError() throws {
        UserDefaults.standard.removeObject(forKey: "text")
    }

    func testDefaultText() throws {
        let textManager = TextManager()
        XCTAssertEqual(textManager.text, "")
    }

    func testSetText() throws {
        let textManager = TextManager()
        textManager.text = "Hello, World!"
        XCTAssertEqual(textManager.text, "Hello, World!")
    }

    func testTextPersistence() throws {
        // Set text
        let textManager1 = TextManager()
        textManager1.text = "Persistent text"

        // Create a new manager - should load persisted text
        let textManager2 = TextManager()
        XCTAssertEqual(textManager2.text, "Persistent text")
    }

    func testEmptyText() throws {
        let textManager = TextManager()
        textManager.text = "Some text"
        textManager.text = ""
        XCTAssertEqual(textManager.text, "")
    }

    func testSpecialCharacters() throws {
        let textManager = TextManager()
        let specialText = "Test with émojis 🎉 and spëcial çharacters!"
        textManager.text = specialText
        XCTAssertEqual(textManager.text, specialText)
    }
}
