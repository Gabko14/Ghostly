//
//  EditorScrollBehavior.swift
//  Ghostly
//

import AppKit

enum EditorScrollBehavior {
    @MainActor
    static func applyTransientScrollbars() {
        for window in NSApplication.shared.windows {
            applyTransientScrollbars(in: window.contentView)
        }
    }

    @MainActor
    static func applyTransientScrollbars(in rootView: NSView?) {
        guard let rootView else { return }

        for scrollView in editorScrollViews(in: rootView) {
            configure(scrollView)
        }
    }

    static func editorScrollViews(in rootView: NSView) -> [NSScrollView] {
        allDescendants(of: rootView)
            .compactMap { $0 as? NSScrollView }
            .filter(isEditorScrollView)
    }

    static func configure(_ scrollView: NSScrollView) {
        scrollView.scrollerStyle = .overlay
        scrollView.autohidesScrollers = true
        scrollView.hasVerticalScroller = true
    }

    static func isEditorScrollView(_ scrollView: NSScrollView) -> Bool {
        containsTextView(in: scrollView.documentView)
    }

    private static func allDescendants(of view: NSView) -> [NSView] {
        [view] + view.subviews.flatMap(allDescendants)
    }

    private static func containsTextView(in view: NSView?) -> Bool {
        guard let view else { return false }
        if view is NSTextView {
            return true
        }

        return view.subviews.contains { containsTextView(in: $0) }
    }
}
