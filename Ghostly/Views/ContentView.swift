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
            // Atmospheric layered background with transparency
            Color.catCrust.opacity(0.5).ignoresSafeArea()

            RadialGradient(
                colors: [Color.catBase.opacity(0.55), Color.catMantle.opacity(0.4)],
                center: .center,
                startRadius: 50,
                endRadius: 300
            ).ignoresSafeArea()

            LinearGradient(
                colors: [Color.catSurface.opacity(0.05), Color.clear],
                startPoint: .top,
                endPoint: .center
            ).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                HeaderView(settingsManager: settingsManager)

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .focused($isTextEditorFocused)
                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                        .tracking(0.3)
                        .lineSpacing(4)
                        .scrollContentBackground(.hidden)
                        .padding(.leading, -5)
                        .foregroundStyle(Color.catText)
                        .accessibilityIdentifier("mainTextEditor")
                    if text.isEmpty {
                        Text(placeholder)
                            .font(.system(size: 14, weight: .regular, design: .monospaced))
                            .foregroundStyle(Color.catOverlay.opacity(0.6))
                    }
                }
                .tint(.catLavender)
                .padding(12)

                // Footer with word/character count
                if !text.isEmpty {
                    FooterView(text: text)
                }
            }

            // Settings overlay
            if settingsManager.isSettingsOpen {
                Button {
                    settingsManager.hideSettings()
                    isTextEditorFocused = true
                } label: {
                    Rectangle()
                        .fill(Color.catCrust.opacity(0.5))
                        .ignoresSafeArea()
                }
                .buttonStyle(.plain)

                SettingsView(settingsManager: settingsManager)
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .scale(scale: 0.98).combined(with: .opacity)
                        )
                    )
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: settingsManager.isSettingsOpen)
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
