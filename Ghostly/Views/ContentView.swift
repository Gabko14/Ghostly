//
//  ContentView.swift
//  Ghostly
//
//  Created by Jay Stakelon on 1/1/21.
//

import SwiftUI
import KeyboardShortcuts

struct ContentView: View {
    var appState: AppState

    @FocusState private var isTextEditorFocused: Bool
    @State private var settingsManager = SettingsManager()

    private let placeholder = "hello there"
    private var tabManager: TabManager { appState.tabManager }

    /// Binding that transforms markdown patterns to visual symbols on text changes
    private var transformedTextBinding: Binding<String> {
        Binding(
            get: { tabManager.activeTabBinding.wrappedValue },
            set: { newValue in
                tabManager.activeTabBinding.wrappedValue = MarkdownTransformer.transform(newValue)
            }
        )
    }

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

                if tabManager.tabs.count > 1 {
                    TabBarView(tabManager: tabManager)
                }

                ZStack(alignment: .topLeading) {
                    let textBinding = transformedTextBinding

                    TextEditor(text: textBinding)
                        .focused($isTextEditorFocused)
                        .font(.system(size: 14, weight: .regular, design: .monospaced))
                        .tracking(0.3)
                        .lineSpacing(4)
                        .scrollContentBackground(.hidden)
                        .padding(.leading, -5)
                        .foregroundStyle(Color.catText)
                        .accessibilityIdentifier("mainTextEditor")

                    if textBinding.wrappedValue.isEmpty {
                        Text(placeholder)
                            .font(.system(size: 14, weight: .regular, design: .monospaced))
                            .foregroundStyle(Color.catOverlay.opacity(0.6))
                    }
                }
                .tint(.catLavender)
                .padding(12)

                // Footer with word/character count
                if let activeTab = tabManager.activeTab, !activeTab.content.isEmpty {
                    FooterView(text: activeTab.content)
                }
            }

            // Hidden buttons for keyboard shortcuts
            keyboardShortcutButtons

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
                .keyboardShortcut(.escape, modifiers: [])

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
        }
        .onChange(of: settingsManager.isSettingsOpen) { _, newValue in
            appState.isSettingsOpen = newValue
        }
        .onChange(of: appState.isSettingsOpen) { _, newValue in
            if newValue {
                settingsManager.showSettings()
            } else {
                settingsManager.hideSettings()
            }
        }
    }

    // MARK: - Keyboard Shortcuts

    @ViewBuilder
    private var keyboardShortcutButtons: some View {
        // Escape - Close popover when settings is not open
        if !settingsManager.isSettingsOpen {
            Button("") {
                appState.isMenuPresented = false
            }
            .keyboardShortcut(.escape, modifiers: [])
            .opacity(0)
            .frame(width: 0, height: 0)
        }
    }
}

#Preview {
    ContentView(appState: AppState())
}
