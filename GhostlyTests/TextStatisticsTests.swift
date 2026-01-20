//
//  TextStatisticsTests.swift
//  GhostlyTests
//
//  Created by Ghostly Contributors
//

import Testing
@testable import Ghostly

@Suite("TextStatistics Tests")
struct TextStatisticsTests {

    // MARK: - Word Count Tests

    @Test("Empty string returns zero words")
    func emptyStringReturnsZeroWords() {
        #expect(TextStatistics.wordCount(for: "") == 0)
    }

    @Test("Single word returns one")
    func singleWordReturnsOne() {
        #expect(TextStatistics.wordCount(for: "hello") == 1)
    }

    @Test("Multiple words separated by spaces")
    func multipleWordsSeparatedBySpaces() {
        #expect(TextStatistics.wordCount(for: "hello world") == 2)
        #expect(TextStatistics.wordCount(for: "one two three four") == 4)
    }

    @Test("Words separated by tabs")
    func wordsSeparatedByTabs() {
        #expect(TextStatistics.wordCount(for: "hello\tworld") == 2)
    }

    @Test("Words separated by newlines")
    func wordsSeparatedByNewlines() {
        #expect(TextStatistics.wordCount(for: "hello\nworld") == 2)
        #expect(TextStatistics.wordCount(for: "one\ntwo\nthree") == 3)
    }

    @Test("Multiple consecutive whitespace handled")
    func multipleConsecutiveWhitespaceHandled() {
        #expect(TextStatistics.wordCount(for: "hello    world") == 2)
        #expect(TextStatistics.wordCount(for: "  leading spaces") == 2)
        #expect(TextStatistics.wordCount(for: "trailing spaces  ") == 2)
        #expect(TextStatistics.wordCount(for: "  both  ") == 1)
    }

    @Test("Mixed whitespace types")
    func mixedWhitespaceTypes() {
        #expect(TextStatistics.wordCount(for: "hello \t\n world") == 2)
        #expect(TextStatistics.wordCount(for: "one\n\n\ttwo   three") == 3)
    }

    @Test("Whitespace only string returns zero")
    func whitespaceOnlyStringReturnsZero() {
        #expect(TextStatistics.wordCount(for: "   ") == 0)
        #expect(TextStatistics.wordCount(for: "\t\t") == 0)
        #expect(TextStatistics.wordCount(for: "\n\n") == 0)
        #expect(TextStatistics.wordCount(for: " \t\n ") == 0)
    }

    // MARK: - Character Count Tests

    @Test("Empty string returns zero characters")
    func emptyStringReturnsZeroCharacters() {
        #expect(TextStatistics.characterCount(for: "") == 0)
    }

    @Test("Single character counted")
    func singleCharacterCounted() {
        #expect(TextStatistics.characterCount(for: "a") == 1)
    }

    @Test("Multiple characters counted")
    func multipleCharactersCounted() {
        #expect(TextStatistics.characterCount(for: "hello") == 5)
        #expect(TextStatistics.characterCount(for: "hello world") == 11)
    }

    @Test("Whitespace included in character count")
    func whitespaceIncludedInCharacterCount() {
        #expect(TextStatistics.characterCount(for: " ") == 1)
        #expect(TextStatistics.characterCount(for: "  ") == 2)
        #expect(TextStatistics.characterCount(for: "a b") == 3)
    }

    @Test("Newlines counted as characters")
    func newlinesCountedAsCharacters() {
        #expect(TextStatistics.characterCount(for: "\n") == 1)
        #expect(TextStatistics.characterCount(for: "a\nb") == 3)
    }

    @Test("Unicode characters counted correctly")
    func unicodeCharactersCountedCorrectly() {
        #expect(TextStatistics.characterCount(for: "café") == 4)
        #expect(TextStatistics.characterCount(for: "日本語") == 3)
        #expect(TextStatistics.characterCount(for: "你好") == 2)
    }

    @Test("Emoji counted as single characters")
    func emojiCountedAsSingleCharacters() {
        #expect(TextStatistics.characterCount(for: "👋") == 1)
        #expect(TextStatistics.characterCount(for: "hello 👋") == 7)
        #expect(TextStatistics.characterCount(for: "🎉🎊🎈") == 3)
    }

    @Test("Complex emoji sequences counted correctly")
    func complexEmojiSequencesCountedCorrectly() {
        // Family emoji (combined characters)
        #expect(TextStatistics.characterCount(for: "👨‍👩‍👧‍👦") == 1)
        // Flag emoji
        #expect(TextStatistics.characterCount(for: "🇺🇸") == 1)
    }
}
