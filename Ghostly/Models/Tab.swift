//
//  Tab.swift
//  Ghostly
//
//  Created by Ghostly Contributors
//

import Foundation

struct GhostlyTab: Identifiable, Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case id
        case content
        case createdAt
        case updatedAt
    }

    let id: UUID
    var content: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        content: String = "",
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let content = try container.decode(String.self, forKey: .content)
        let createdAt = try container.decode(Date.self, forKey: .createdAt)
        let updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)

        self.init(id: id, content: content, createdAt: createdAt, updatedAt: updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(content, forKey: .content)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }

    /// Title derived from first line of content, truncated by visual width.
    /// CJK/fullwidth characters count as 2 units; others count as 1.
    var title: String {
        let firstLine = content
            .split(separator: "\n", maxSplits: 1)
            .first
            .map(String.init)?
            .trimmingCharacters(in: .whitespaces) ?? ""

        guard !firstLine.isEmpty else { return "Untitled" }

        let maxVisualWidth = 20
        let ellipsisWidth = 3 // "..." is 3 visual units

        let totalWidth = firstLine.unicodeScalars.reduce(0) { $0 + Self.visualWidth(of: $1) }
        guard totalWidth > maxVisualWidth else { return firstLine }

        var width = 0
        let targetWidth = maxVisualWidth - ellipsisWidth
        var endIndex = firstLine.startIndex
        for index in firstLine.indices {
            let charWidth = firstLine[index].unicodeScalars.reduce(0) { $0 + Self.visualWidth(of: $1) }
            if width + charWidth > targetWidth { break }
            width += charWidth
            endIndex = firstLine.index(after: index)
        }

        return String(firstLine[firstLine.startIndex..<endIndex]) + "..."
    }

    /// Returns visual width of a Unicode scalar: 2 for CJK/fullwidth, 1 otherwise.
    private static func visualWidth(of scalar: Unicode.Scalar) -> Int {
        let v = scalar.value
        // CJK Unified Ideographs
        if (0x4E00...0x9FFF).contains(v) { return 2 }
        // CJK Extension A
        if (0x3400...0x4DBF).contains(v) { return 2 }
        // CJK Extension B+
        if (0x20000...0x2A6DF).contains(v) { return 2 }
        // CJK Compatibility Ideographs
        if (0xF900...0xFAFF).contains(v) { return 2 }
        // Fullwidth Forms
        if (0xFF01...0xFF60).contains(v) { return 2 }
        // Fullwidth currency symbols
        if (0xFFE0...0xFFE6).contains(v) { return 2 }
        // Hangul Syllables
        if (0xAC00...0xD7AF).contains(v) { return 2 }
        // Hangul Jamo
        if (0x1100...0x11FF).contains(v) { return 2 }
        // Hangul Compatibility Jamo
        if (0x3130...0x318F).contains(v) { return 2 }
        // CJK Radicals / Kangxi
        if (0x2E80...0x2FDF).contains(v) { return 2 }
        // CJK Symbols and Punctuation
        if (0x3000...0x303F).contains(v) { return 2 }
        // Hiragana
        if (0x3040...0x309F).contains(v) { return 2 }
        // Katakana
        if (0x30A0...0x30FF).contains(v) { return 2 }
        // Katakana Phonetic Extensions
        if (0x31F0...0x31FF).contains(v) { return 2 }
        // Bopomofo
        if (0x3100...0x312F).contains(v) { return 2 }
        // Enclosed CJK Letters
        if (0x3200...0x32FF).contains(v) { return 2 }
        // CJK Compatibility
        if (0x3300...0x33FF).contains(v) { return 2 }
        return 1
    }
}
