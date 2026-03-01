//
//  EditorScrollBehavior.swift
//  Ghostly
//

import AppKit

enum EditorScrollBehavior {
    @MainActor
    static func applyTransientScrollbars() {
        guard let rootView = activeWindowRootView() else { return }
        applyTransientScrollbars(in: rootView)
    }

    @MainActor
    static func applyTransientScrollbars(in rootView: NSView?) {
        guard let rootView, let scrollView = editorScrollView(in: rootView) else { return }
        configure(scrollView)
    }

    static func editorScrollViews(in rootView: NSView) -> [NSScrollView] {
        let candidates = allDescendants(of: rootView)
            .compactMap { $0 as? NSScrollView }
            .filter(isEditorScrollView)

        // SwiftUI can nest the text editor scroll view inside larger container scroll views.
        // We only want the innermost editor-backed scroll view, otherwise multiple scrollbars
        // can be configured and rendered.
        return candidates.filter { candidate in
            !candidates.contains { other in
                other !== candidate && other.isDescendant(of: candidate)
            }
        }
    }

    static func editorScrollView(in rootView: NSView) -> NSScrollView? {
        editorScrollViews(in: rootView)
            .max { lhs, rhs in
                depth(of: lhs) < depth(of: rhs)
            }
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

    @MainActor
    private static func activeWindowRootView() -> NSView? {
        let activeWindow = NSApplication.shared.keyWindow
            ?? NSApplication.shared.mainWindow
            ?? NSApplication.shared.windows.first(where: \.isVisible)
        return activeWindow?.contentView
    }

    private static func containsTextView(in view: NSView?) -> Bool {
        guard let view else { return false }
        if view is NSTextView {
            return true
        }

        return view.subviews.contains { containsTextView(in: $0) }
    }

    private static func depth(of view: NSView) -> Int {
        var depth = 0
        var ancestor = view.superview

        while let current = ancestor {
            depth += 1
            ancestor = current.superview
        }

        return depth
    }
}
