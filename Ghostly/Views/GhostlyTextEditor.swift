//
//  GhostlyTextEditor.swift
//  Ghostly
//

import AppKit
import SwiftUI

struct GhostlyTextEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    @MainActor
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = EditorTextViewConfiguration.makeScrollView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        EditorTextViewConfiguration.updateText(text, in: textView)
        textView.delegate = context.coordinator
        textView.setAccessibilityIdentifier("mainTextEditor")

        context.coordinator.textView = textView
        context.coordinator.applyFocusIfNeeded()

        return scrollView
    }

    @MainActor
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self

        guard let textView = scrollView.documentView as? NSTextView else { return }

        context.coordinator.performProgrammaticUpdate {
            EditorTextViewConfiguration.updateText(text, in: textView)
        }

        context.coordinator.textView = textView
        context.coordinator.applyFocusIfNeeded()
    }
}

extension GhostlyTextEditor {
    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: GhostlyTextEditor
        weak var textView: NSTextView?
        private var isProgrammaticUpdate = false

        init(parent: GhostlyTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard !isProgrammaticUpdate,
                  let textView = notification.object as? NSTextView else { return }

            parent.text = textView.string
        }

        func textDidBeginEditing(_ notification: Notification) {
            if !parent.isFocused {
                parent.isFocused = true
            }
        }

        func textDidEndEditing(_ notification: Notification) {
            if parent.isFocused {
                parent.isFocused = false
            }
        }

        func performProgrammaticUpdate(_ updates: () -> Void) {
            isProgrammaticUpdate = true
            updates()
            isProgrammaticUpdate = false
        }

        func applyFocusIfNeeded() {
            guard parent.isFocused, let textView else { return }

            if let window = textView.window {
                if window.firstResponder !== textView {
                    window.makeFirstResponder(textView)
                }
                return
            }

            Task { @MainActor [weak textView] in
                guard let textView, let window = textView.window else { return }
                if window.firstResponder !== textView {
                    window.makeFirstResponder(textView)
                }
            }
        }
    }
}
