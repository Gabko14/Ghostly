//
//  MarkdownTransformer.swift
//  Ghostly
//
//  Transforms markdown patterns to visual symbols in-place.
//

import Foundation

struct MarkdownTransformer {
    /// Transforms markdown patterns to visual symbols.
    /// - `[ ]` or `[]` → ☐ (unchecked box)
    /// - `[x]` or `[X]` → ☑ (checked box)
    /// - `- ` or `* ` at line start → • (bullet point)
    /// - `**text**` → 𝐭𝐞𝐱𝐭 (unicode bold)
    /// - Auto-continues lists when Enter is pressed
    static func transform(_ text: String, previousText: String? = nil) -> String {
        var result = text

        // Auto-continue lists when newline is added
        if let previous = previousText {
            result = autoContinueList(newText: result, previousText: previous)
        }

        // Checkboxes (must check before bullets since [ ] contains space)
        result = result.replacingOccurrences(of: "[ ] ", with: "☐ ")
        result = result.replacingOccurrences(of: "[] ", with: "☐ ")
        result = result.replacingOccurrences(of: "[x] ", with: "☑ ")
        result = result.replacingOccurrences(of: "[X] ", with: "☑ ")

        // Bullets at line start only
        let lines = result.components(separatedBy: "\n")
        let transformed = lines.map { line -> String in
            if line.hasPrefix("- ") || line.hasPrefix("* ") {
                return "• " + line.dropFirst(2)
            }
            return line
        }
        result = transformed.joined(separator: "\n")

        // Bold text: **text** → unicode bold
        result = transformBold(result)

        return result
    }

    /// Detects when a newline is inserted after a list item and auto-continues the list
    private static func autoContinueList(newText: String, previousText: String) -> String {
        // Only process if exactly one newline was added
        let newLines = newText.components(separatedBy: "\n")
        let oldLines = previousText.components(separatedBy: "\n")

        guard newLines.count == oldLines.count + 1 else { return newText }

        // Find where the new line was inserted
        var insertIndex = 0
        for i in 0..<oldLines.count {
            if i >= newLines.count || newLines[i] != oldLines[i] {
                insertIndex = i
                break
            }
            insertIndex = i + 1
        }

        // Check if the line before the new line is a list item
        guard insertIndex > 0 && insertIndex < newLines.count else { return newText }

        let previousLine = newLines[insertIndex - 1]
        let newLine = newLines[insertIndex]

        // Only auto-continue if the new line is empty (user just pressed Enter)
        guard newLine.isEmpty else { return newText }

        // Determine the prefix to add based on previous line
        let prefix: String?
        if previousLine.hasPrefix("• ") {
            prefix = "• "
        } else if previousLine.hasPrefix("☐ ") {
            prefix = "☐ "
        } else if previousLine.hasPrefix("☑ ") {
            prefix = "☐ "  // New checkbox starts unchecked
        } else {
            prefix = nil
        }

        guard let listPrefix = prefix else { return newText }

        // Don't auto-continue if previous line is just the prefix (empty list item)
        if previousLine.trimmingCharacters(in: .whitespaces) == listPrefix.trimmingCharacters(in: .whitespaces) {
            return newText
        }

        // Insert the prefix on the new line
        var modifiedLines = newLines
        modifiedLines[insertIndex] = listPrefix
        return modifiedLines.joined(separator: "\n")
    }

    /// Transforms **text** to unicode mathematical bold
    private static func transformBold(_ text: String) -> String {
        var result = ""
        var i = text.startIndex

        while i < text.endIndex {
            // Look for **
            if text[i] == "*",
               let nextIndex = text.index(i, offsetBy: 1, limitedBy: text.endIndex),
               nextIndex < text.endIndex,
               text[nextIndex] == "*" {

                // Find closing **
                let contentStart = text.index(nextIndex, offsetBy: 1, limitedBy: text.endIndex) ?? text.endIndex
                if contentStart < text.endIndex,
                   let closingRange = text.range(of: "**", range: contentStart..<text.endIndex) {

                    let boldContent = String(text[contentStart..<closingRange.lowerBound])

                    // Only transform if there's actual content (not empty or just spaces)
                    if !boldContent.isEmpty && !boldContent.allSatisfy({ $0.isWhitespace }) {
                        result += toBold(boldContent)
                        i = closingRange.upperBound
                        continue
                    }
                }
            }

            result.append(text[i])
            i = text.index(after: i)
        }

        return result
    }

    /// Converts text to unicode mathematical bold characters
    private static func toBold(_ text: String) -> String {
        text.map { char -> String in
            let scalar = char.unicodeScalars.first!.value

            // A-Z → Mathematical Bold A-Z (U+1D400 - U+1D419)
            if scalar >= 0x41 && scalar <= 0x5A {
                return String(UnicodeScalar(0x1D400 + (scalar - 0x41))!)
            }
            // a-z → Mathematical Bold a-z (U+1D41A - U+1D433)
            if scalar >= 0x61 && scalar <= 0x7A {
                return String(UnicodeScalar(0x1D41A + (scalar - 0x61))!)
            }
            // 0-9 → Mathematical Bold 0-9 (U+1D7CE - U+1D7D7)
            if scalar >= 0x30 && scalar <= 0x39 {
                return String(UnicodeScalar(0x1D7CE + (scalar - 0x30))!)
            }
            // Keep other characters as-is
            return String(char)
        }.joined()
    }
}
