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
    static func transform(_ text: String) -> String {
        var result = text

        // Checkboxes (must check before bullets since [ ] contains space)
        result = result.replacingOccurrences(of: "[ ] ", with: "☐ ")
        result = result.replacingOccurrences(of: "[] ", with: "☐ ")
        result = result.replacingOccurrences(of: "[x] ", with: "☑ ")
        result = result.replacingOccurrences(of: "[X] ", with: "☑ ")

        // Bullets at line start only
        let lines = result.components(separatedBy: "\n")
        let transformed = lines.map { line -> String in
            if line.hasPrefix("- ") {
                return "• " + line.dropFirst(2)
            }
            if line.hasPrefix("* ") {
                return "• " + line.dropFirst(2)
            }
            return line
        }
        return transformed.joined(separator: "\n")
    }
}
