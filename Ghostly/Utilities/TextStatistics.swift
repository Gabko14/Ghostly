//
//  TextStatistics.swift
//  Ghostly
//
//  Created by Ghostly Contributors
//

import Foundation

/// Utilities for calculating text statistics like word and character counts.
struct TextStatistics {

    /// Counts words in the given text.
    /// Words are separated by whitespace or newlines.
    /// Empty strings return 0.
    static func wordCount(for text: String) -> Int {
        text.split { $0.isWhitespace || $0.isNewline }
            .filter { !$0.isEmpty }
            .count
    }

    /// Counts characters in the given text.
    /// Returns the total number of characters including whitespace.
    static func characterCount(for text: String) -> Int {
        text.count
    }
}
