//
//  EditorTextViewConfiguration.swift
//  Ghostly
//

import AppKit
import SwiftUI

enum EditorTextViewConfiguration {
    static let fontSize: CGFloat = 14
    static let tracking: CGFloat = 0.3
    static let lineSpacing: CGFloat = 4

    @MainActor
    static func makeScrollView() -> NSScrollView {
        let scrollView = NSTextView.scrollablePlainDocumentContentTextView()
        configure(scrollView)

        if let textView = scrollView.documentView as? NSTextView {
            configure(textView)
        }

        return scrollView
    }

    @MainActor
    static func configure(_ scrollView: NSScrollView) {
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.scrollerStyle = .overlay
        scrollView.drawsBackground = false
        scrollView.backgroundColor = .clear
        scrollView.contentInsets = NSEdgeInsets()
    }

    @MainActor
    static func configure(_ textView: NSTextView) {
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.textColor = NSColor(Color.catText)
        textView.insertionPointColor = NSColor(Color.catLavender)
        textView.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.minSize = .zero
        textView.maxSize = .init(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.textContainerInset = .zero
        textView.typingAttributes = textAttributes()

        if let textContainer = textView.textContainer {
            textContainer.widthTracksTextView = true
            textContainer.containerSize = .init(
                width: textView.bounds.width,
                height: .greatestFiniteMagnitude
            )
            textContainer.lineFragmentPadding = 0
        }
    }

    @MainActor
    static func updateText(_ text: String, in textView: NSTextView) {
        guard textView.string != text else {
            textView.typingAttributes = textAttributes()
            return
        }

        let selectedRanges = textView.selectedRanges
        textView.textStorage?.setAttributedString(normalizedAttributedString(for: text))
        textView.selectedRanges = clampedSelectedRanges(selectedRanges, maxLength: text.utf16.count)
        textView.typingAttributes = textAttributes()
        resetScrollState(for: textView)
    }

    @MainActor
    private static func normalizedAttributedString(for text: String) -> NSAttributedString {
        NSAttributedString(string: text, attributes: textAttributes())
    }

    @MainActor
    private static func textAttributes() -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing

        return [
            .font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular),
            .foregroundColor: NSColor(Color.catText),
            .kern: tracking,
            .paragraphStyle: paragraphStyle
        ]
    }

    private static func clampedSelectedRanges(_ ranges: [Any], maxLength: Int) -> [NSValue] {
        ranges.compactMap { value in
            guard let range = (value as? NSValue)?.rangeValue else { return nil }

            let location = min(range.location, maxLength)
            let length = min(range.length, maxLength - location)
            return NSValue(range: NSRange(location: location, length: length))
        }
    }

    @MainActor
    private static func resetScrollState(for textView: NSTextView) {
        guard let scrollView = textView.enclosingScrollView else { return }

        textView.scrollRangeToVisible(NSRange(location: 0, length: 0))
        scrollView.contentView.scroll(to: .zero)
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }
}
