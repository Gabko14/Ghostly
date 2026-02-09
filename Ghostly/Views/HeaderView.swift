//
//  HeaderView.swift
//  Ghostly
//
//  Created by Jay Stakelon on 1/30/21.
//

import SwiftUI

struct HeaderView: View {
    var settingsManager: SettingsManager
    @State private var isHovered = false
    @State private var isPreviewButtonHovered = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Gradient title with wide tracking for ethereal feel
                Text("Ghostly")
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .tracking(2.5)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.catLavender, Color.catText.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(isHovered ? 1 : 0.9)
                    .onHover { hovering in
                        withAnimation(.easeOut(duration: 0.2)) {
                            isHovered = hovering
                        }
                    }
                    .accessibilityIdentifier("headerTitle")

                Spacer()

                // Preview toggle button
                Button {
                    settingsManager.togglePreviewMode()
                } label: {
                    Image(systemName: settingsManager.isPreviewMode ? "eye" : "doc.plaintext")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(isPreviewButtonHovered ? Color.catText : Color.catLavender)
                        .brightness(isPreviewButtonHovered ? 0.05 : 0)
                        .animation(.easeOut(duration: 0.15), value: isPreviewButtonHovered)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isPreviewButtonHovered = hovering
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .accessibilityLabel(settingsManager.isPreviewMode ? "Toggle editor" : "Toggle preview")
                .help(settingsManager.isPreviewMode ? "Edit markdown (\u{21E7}\u{2318}P)" : "Preview markdown (\u{21E7}\u{2318}P)")
                .accessibilityIdentifier("previewToggleButton")

                // Menu button
                DropdownMenuView(settingsManager: settingsManager)
                    .frame(width: 28, height: 28)
                    .accessibilityIdentifier("menuButton")
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)

            // Subtle horizontal divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.catSurface0.opacity(0),
                            Color.catSurface0.opacity(0.5),
                            Color.catSurface0.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 12)
        }
    }
}
