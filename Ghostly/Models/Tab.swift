//
//  Tab.swift
//  Ghostly
//
//  Created by Ghostly Contributors
//

import Foundation

struct GhostlyTab: Identifiable, Codable, Equatable {
    let id: UUID
    var content: String
    var createdAt: Date

    init(id: UUID = UUID(), content: String = "", createdAt: Date = Date()) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
    }

    /// Title derived from first line of content, truncated to 20 characters
    var title: String {
        let firstLine = content
            .split(separator: "\n", maxSplits: 1)
            .first
            .map(String.init)?
            .trimmingCharacters(in: .whitespaces) ?? ""

        guard !firstLine.isEmpty else { return "Untitled" }
        guard firstLine.count > 20 else { return firstLine }

        return String(firstLine.prefix(17)) + "..."
    }
}
