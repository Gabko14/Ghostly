//
//  NotebarTests.swift
//  NotebarTests
//
//  Created by Ghostly Contributors
//

import XCTest
@testable import Notebar

final class NotebarTests: XCTestCase {

    override func setUpWithError() throws {
        // Reset UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: "text")
        UserDefaults.standard.removeObject(forKey: "theme")
    }

    override func tearDownWithError() throws {
        // Clean up UserDefaults after each test
        UserDefaults.standard.removeObject(forKey: "text")
        UserDefaults.standard.removeObject(forKey: "theme")
    }
}
