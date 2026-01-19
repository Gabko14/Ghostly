//
//  ContentView.swift
//  Ghostly
//
//  Created by Jay Stakelon on 1/1/21.
//

import SwiftUI
import KeyboardShortcuts

struct ContentView: View {
    private var placeholder: String = "hello there"
    @FocusState private var isTextEditorFocused: Bool
    @State private var settingsManager = SettingsManager()
    @AppStorage("text") private var text: String = ""

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                HeaderView(settingsManager: settingsManager)
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .focused($isTextEditorFocused)
                        .font(Font.system(.body, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding(.leading, -5)
                        .foregroundStyle(.primary)
                        .accessibilityIdentifier("mainTextEditor")
                    if text.isEmpty {
                        Text(placeholder)
                            .font(Font.system(.body, design: .monospaced))
                            .foregroundStyle(.primary)
                            .opacity(0.4)
                    }
                }.accentColor(.yellow)
                .padding(12)
            }

            if settingsManager.isSettingsOpen {
                Button {
                    settingsManager.hideSettings()
                    isTextEditorFocused = true
                } label: {
                    Rectangle()
                        .fill(Color.black.opacity(0.3))
                        .ignoresSafeArea()
                }
                .buttonStyle(.plain)

                SettingsView(settingsManager: settingsManager)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: settingsManager.isSettingsOpen)
        .onAppear {
            isTextEditorFocused = true
            KeyboardShortcuts.onKeyUp(for: .toggleSettings) { [self] in
                Task { @MainActor in
                    settingsManager.toggleSettings()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
