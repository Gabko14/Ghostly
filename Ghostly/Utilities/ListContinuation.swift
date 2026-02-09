//
//  ListContinuation.swift
//  Ghostly
//
//  Auto-continues lists when Enter is pressed after a list item.
//

import Foundation

struct ListContinuation {
    /// Detects when a newline is inserted after a list item and auto-continues the list.
    /// Supports markdown bullets (`- `), unchecked checkboxes (`- [ ] `), and checked checkboxes (`- [x] `).
    static func autoContinueList(newText: String, previousText: String) -> String {
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

        guard insertIndex > 0 && insertIndex < newLines.count else { return newText }

        let previousLine = newLines[insertIndex - 1]
        let newLine = newLines[insertIndex]

        // Only auto-continue if the new line is empty (user just pressed Enter)
        guard newLine.isEmpty else { return newText }

        // Determine the prefix to add based on previous line
        let prefix: String?
        if previousLine.hasPrefix("- [x] ") || previousLine.hasPrefix("- [X] ") {
            prefix = "- [ ] "  // Checked checkbox continues as unchecked
        } else if previousLine.hasPrefix("- [ ] ") {
            prefix = "- [ ] "
        } else if previousLine.hasPrefix("- ") {
            prefix = "- "
        } else if previousLine.hasPrefix("* ") {
            prefix = "* "
        } else {
            prefix = nil
        }

        guard let listPrefix = prefix else { return newText }

        // Don't auto-continue if previous line is just the prefix (empty list item)
        if previousLine.trimmingCharacters(in: .whitespaces) == listPrefix.trimmingCharacters(in: .whitespaces) {
            return newText
        }

        var modifiedLines = newLines
        modifiedLines[insertIndex] = listPrefix
        return modifiedLines.joined(separator: "\n")
    }
}
