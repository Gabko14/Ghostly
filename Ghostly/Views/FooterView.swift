//
//  FooterView.swift
//  Ghostly
//
//  Word and character count indicator
//

import SwiftUI

struct FooterView: View {
    let text: String

    private var wordCount: Int {
        TextStatistics.wordCount(for: text)
    }

    private var characterCount: Int {
        TextStatistics.characterCount(for: text)
    }

    var body: some View {
        HStack {
            Spacer()
            Text("\(wordCount) words | \(characterCount) chars")
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundStyle(Color.catOverlay.opacity(0.7))
                .accessibilityIdentifier("footerStats")
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
}

#Preview {
    FooterView(text: "Hello world, this is a test")
        .background(Color.catBase)
}
