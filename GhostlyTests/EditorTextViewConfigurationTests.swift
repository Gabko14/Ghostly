//
//  EditorTextViewConfigurationTests.swift
//  GhostlyTests
//

import AppKit
import Testing
@testable import Ghostly

@Suite("EditorTextViewConfiguration Tests")
@MainActor
struct EditorTextViewConfigurationTests {

    @Test("Configures overlay autohiding scrollbars")
    func configuresOverlayAutohidingScrollbars() {
        let scrollView = EditorTextViewConfiguration.makeScrollView()
        let textView = scrollView.documentView as? NSTextView

        #expect(scrollView.scrollerStyle == .overlay)
        #expect(scrollView.autohidesScrollers)
        #expect(scrollView.hasVerticalScroller)
        #expect(scrollView.hasHorizontalScroller == false)
        #expect(scrollView.drawsBackground == false)
        #expect(textView != nil)
        #expect(textView?.isRichText == false)
        #expect(textView?.isHorizontallyResizable == false)
        #expect(textView?.textContainer?.widthTracksTextView == true)
    }

    @Test("Configures text view for plain text editing")
    func configuresTextViewForPlainTextEditing() {
        let textView = NSTextView()

        EditorTextViewConfiguration.configure(textView)

        #expect(textView.isRichText == false)
        #expect(textView.importsGraphics == false)
        #expect(textView.drawsBackground == false)
        #expect(textView.allowsUndo)
        #expect(textView.isHorizontallyResizable == false)
        #expect(textView.textContainerInset == .zero)
        #expect(textView.textContainer?.lineFragmentPadding == 0)
        #expect(textView.font?.pointSize == EditorTextViewConfiguration.fontSize)
    }

    @Test("Updating text preserves style and clamps selection")
    func updatingTextPreservesStyleAndClampsSelection() {
        let textView = NSTextView()
        EditorTextViewConfiguration.configure(textView)
        textView.string = "Hello world"
        textView.selectedRanges = [NSValue(range: NSRange(location: 11, length: 0))]

        EditorTextViewConfiguration.updateText("Hi", in: textView)

        #expect(textView.string == "Hi")

        let selectedRange = (textView.selectedRanges.first as? NSValue)?.rangeValue
        #expect(selectedRange == NSRange(location: 2, length: 0))

        let attributes = textView.textStorage?.attributes(at: 0, effectiveRange: nil)
        #expect((attributes?[.kern] as? CGFloat) == EditorTextViewConfiguration.tracking)
    }

    @Test("Updating text resets the reused scroll view to the top")
    func updatingTextResetsScrollPosition() {
        let scrollView = EditorTextViewConfiguration.makeScrollView()
        scrollView.frame = NSRect(x: 0, y: 0, width: 300, height: 120)

        let textView = scrollView.documentView as? NSTextView
        #expect(textView != nil)

        if let textView {
            let longText = Array(repeating: "A long enough line to force scrolling.", count: 60)
                .joined(separator: "\n")
            EditorTextViewConfiguration.updateText(longText, in: textView)
            textView.layoutManager?.ensureLayout(for: textView.textContainer!)
            textView.scrollRangeToVisible(NSRange(location: longText.utf16.count, length: 0))
            scrollView.reflectScrolledClipView(scrollView.contentView)
            #expect(scrollView.contentView.bounds.origin.y > 0)

            EditorTextViewConfiguration.updateText("", in: textView)
        }

        #expect(scrollView.contentView.bounds.origin == .zero)
    }
}
