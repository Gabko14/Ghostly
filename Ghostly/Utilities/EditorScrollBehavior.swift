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

    @MainActor
    static func editorScrollViews(in rootView: NSView) -> [NSScrollView] {
        uniqueScrollViews(
            allDescendants(of: rootView)
                .compactMap { $0 as? NSTextView }
                .compactMap { $0.enclosingScrollView }
        )
    }

    @MainActor
    static func editorScrollView(in rootView: NSView) -> NSScrollView? {
        editorScrollViews(in: rootView).first
    }

    @MainActor
    static func configure(_ scrollView: NSScrollView) {
        scrollView.scrollerStyle = .overlay
        scrollView.autohidesScrollers = true
        scrollView.hasVerticalScroller = true
    }

    @MainActor
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

    @MainActor
    private static func uniqueScrollViews(_ scrollViews: [NSScrollView]) -> [NSScrollView] {
        var seen = Set<ObjectIdentifier>()

        return scrollViews.filter { scrollView in
            let identifier = ObjectIdentifier(scrollView)
            if seen.contains(identifier) {
                return false
            }

            seen.insert(identifier)
            return true
        }
    }
}
