//
//  EditorScrollBehaviorTests.swift
//  GhostlyTests
//

import AppKit
import Testing
@testable import Ghostly

@Suite("EditorScrollBehavior Tests")
@MainActor
struct EditorScrollBehaviorTests {

    @Test("Finds the text editor scroll view")
    func findsTextEditorScrollView() {
        let rootView = NSView(frame: .init(x: 0, y: 0, width: 300, height: 300))
        let editorScrollView = NSScrollView()
        editorScrollView.documentView = NSTextView()
        rootView.addSubview(editorScrollView)

        let matches = EditorScrollBehavior.editorScrollViews(in: rootView)

        #expect(matches == [editorScrollView])
    }

    @Test("Ignores non-editor scroll views")
    func ignoresNonEditorScrollViews() {
        let rootView = NSView(frame: .init(x: 0, y: 0, width: 300, height: 300))
        let genericScrollView = NSScrollView()
        genericScrollView.documentView = NSView()
        rootView.addSubview(genericScrollView)

        let matches = EditorScrollBehavior.editorScrollViews(in: rootView)

        #expect(matches.isEmpty)
    }

    @Test("Configures overlay autohiding scrollbars")
    func configuresOverlayAutohidingScrollbars() {
        let scrollView = NSScrollView()
        scrollView.scrollerStyle = .legacy
        scrollView.autohidesScrollers = false
        scrollView.hasVerticalScroller = false

        EditorScrollBehavior.configure(scrollView)

        #expect(scrollView.scrollerStyle == .overlay)
        #expect(scrollView.autohidesScrollers)
        #expect(scrollView.hasVerticalScroller)
    }
}
