//
//  GhostlyModifiers.swift
//  Ghostly
//
//  Custom view modifiers for the Ghostly ethereal aesthetic
//

import SwiftUI
import AppKit

// MARK: - Inner Glow Modifier

struct InnerGlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let intensity: CGFloat
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color.opacity(intensity), lineWidth: 1)
                    .blur(radius: radius)
            )
    }
}

extension View {
    func innerGlow(
        _ color: Color = .catLavender,
        radius: CGFloat = 4,
        intensity: CGFloat = 0.3,
        cornerRadius: CGFloat = 12
    ) -> some View {
        modifier(
            InnerGlowModifier(
                color: color,
                radius: radius,
                intensity: intensity,
                cornerRadius: cornerRadius
            )
        )
    }
}

// MARK: - Theme Shadow Modifier

struct CatShadowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: radius, x: x, y: y)
    }
}

extension View {
    func catShadow(color: Color = .catCrust, radius: CGFloat = 8, x: CGFloat = 0, y: CGFloat = 4) -> some View {
        modifier(CatShadowModifier(color: color, radius: radius, x: x, y: y))
    }
}

// MARK: - TextEditor Scrollbar Behavior

struct TextEditorScrollbarBehavior: NSViewRepresentable {
    var fadeDelay: TimeInterval = 1.0

    func makeCoordinator() -> Coordinator {
        Coordinator(fadeDelay: fadeDelay)
    }

    func makeNSView(context: Context) -> NSView {
        let anchorView = NSView(frame: .zero)
        Task { @MainActor in
            context.coordinator.attachIfNeeded(from: anchorView)
        }
        return anchorView
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        Task { @MainActor in
            context.coordinator.fadeDelay = fadeDelay
            context.coordinator.attachIfNeeded(from: nsView)
            context.coordinator.updateScrollerVisibility()
        }
    }
}

extension TextEditorScrollbarBehavior {
    @MainActor
    final class Coordinator {
        var fadeDelay: TimeInterval

        private weak var scrollView: NSScrollView?
        private weak var observedDocumentView: NSView?
        private var clipBoundsObserver: NSObjectProtocol?
        private var documentFrameObserver: NSObjectProtocol?
        private var scrollViewFrameObserver: NSObjectProtocol?
        private var fadeWorkItem: DispatchWorkItem?

        init(fadeDelay: TimeInterval) {
            self.fadeDelay = fadeDelay
        }

        func attachIfNeeded(from anchorView: NSView) {
            guard let resolvedScrollView = locateTextEditorScrollView(from: anchorView) else {
                return
            }

            guard resolvedScrollView !== scrollView else {
                return
            }

            detachObservers()
            scrollView = resolvedScrollView
            configure(scrollView: resolvedScrollView)
            updateScrollerVisibility()
        }

        func updateScrollerVisibility() {
            guard let scrollView else {
                return
            }

            updateDocumentFrameObserverIfNeeded(for: scrollView)

            let canScroll = canScrollVertically(in: scrollView)
            scrollView.scrollerStyle = .overlay
            scrollView.hasVerticalScroller = canScroll

            guard let verticalScroller = scrollView.verticalScroller else {
                return
            }

            verticalScroller.isHidden = !canScroll
            if !canScroll {
                fadeWorkItem?.cancel()
                verticalScroller.alphaValue = 0
            }
        }

        private func configure(scrollView: NSScrollView) {
            scrollView.scrollerStyle = .overlay
            scrollView.hasVerticalScroller = true
            scrollView.autohidesScrollers = false
            scrollView.contentView.postsBoundsChangedNotifications = true
            scrollView.postsFrameChangedNotifications = true

            clipBoundsObserver = NotificationCenter.default.addObserver(
                forName: NSView.boundsDidChangeNotification,
                object: scrollView.contentView,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.handleScrollActivity()
                }
            }

            scrollViewFrameObserver = NotificationCenter.default.addObserver(
                forName: NSView.frameDidChangeNotification,
                object: scrollView,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.updateScrollerVisibility()
                }
            }
        }

        private func updateDocumentFrameObserverIfNeeded(for scrollView: NSScrollView) {
            guard scrollView.documentView !== observedDocumentView else {
                return
            }

            if let documentFrameObserver {
                NotificationCenter.default.removeObserver(documentFrameObserver)
                self.documentFrameObserver = nil
            }

            observedDocumentView = scrollView.documentView
            observedDocumentView?.postsFrameChangedNotifications = true

            if let observedDocumentView {
                documentFrameObserver = NotificationCenter.default.addObserver(
                    forName: NSView.frameDidChangeNotification,
                    object: observedDocumentView,
                    queue: .main
                ) { [weak self] _ in
                    Task { @MainActor [weak self] in
                        self?.updateScrollerVisibility()
                    }
                }
            }
        }

        private func handleScrollActivity() {
            guard let scrollView else {
                return
            }

            updateScrollerVisibility()

            guard canScrollVertically(in: scrollView), let verticalScroller = scrollView.verticalScroller else {
                return
            }

            verticalScroller.isHidden = false
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.1
                verticalScroller.animator().alphaValue = 1
            }

            scheduleFade()
        }

        private func scheduleFade() {
            fadeWorkItem?.cancel()

            let workItem = DispatchWorkItem { [weak self] in
                Task { @MainActor [weak self] in
                    self?.fadeScrollerIfNeeded()
                }
            }
            fadeWorkItem = workItem

            DispatchQueue.main.asyncAfter(deadline: .now() + fadeDelay, execute: workItem)
        }

        private func fadeScrollerIfNeeded() {
            guard let scrollView, canScrollVertically(in: scrollView), let verticalScroller = scrollView.verticalScroller else {
                return
            }

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.22
                verticalScroller.animator().alphaValue = 0
            }
        }

        private func canScrollVertically(in scrollView: NSScrollView) -> Bool {
            guard let documentView = scrollView.documentView else {
                return false
            }

            let visibleHeight = scrollView.contentView.bounds.height
            guard visibleHeight > 0 else {
                return false
            }

            let contentHeight = max(documentView.frame.height, documentView.fittingSize.height)
            return (contentHeight - visibleHeight) > 1
        }

        private func locateTextEditorScrollView(from anchorView: NSView) -> NSScrollView? {
            var node: NSView? = anchorView
            while let currentNode = node {
                if let scrollView = findTextEditorScrollView(in: currentNode) {
                    return scrollView
                }
                node = currentNode.superview
            }
            return nil
        }

        private func findTextEditorScrollView(in view: NSView) -> NSScrollView? {
            if let scrollView = view as? NSScrollView, scrollView.documentView is NSTextView {
                return scrollView
            }

            for subview in view.subviews {
                if let found = findTextEditorScrollView(in: subview) {
                    return found
                }
            }

            return nil
        }

        private func detachObservers() {
            if let clipBoundsObserver {
                NotificationCenter.default.removeObserver(clipBoundsObserver)
                self.clipBoundsObserver = nil
            }

            if let documentFrameObserver {
                NotificationCenter.default.removeObserver(documentFrameObserver)
                self.documentFrameObserver = nil
            }

            if let scrollViewFrameObserver {
                NotificationCenter.default.removeObserver(scrollViewFrameObserver)
                self.scrollViewFrameObserver = nil
            }

            fadeWorkItem?.cancel()
            fadeWorkItem = nil
            observedDocumentView = nil
            scrollView = nil
        }
    }
}
