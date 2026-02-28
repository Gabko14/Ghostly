//
//  HeaderView.swift
//  Ghostly
//
//  Created by Jay Stakelon on 1/30/21.
//

import SwiftUI

struct HeaderView: View {
    @Bindable var appState: AppState
    @State private var isHovered = false

    private var settingsManager: SettingsManager { appState.settingsManager }

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

                // Pin button — keeps window open when focus moves to another app
                Button {
                    appState.isPinned.toggle()
                } label: {
                    Image(systemName: appState.isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 12))
                        .foregroundStyle(appState.isPinned ? Color.catLavender : Color.catOverlay.opacity(0.7))
                        .rotationEffect(.degrees(45))
                }
                .buttonStyle(.plain)
                .frame(width: 28, height: 28)
                .help(appState.isPinned ? "Unpin (window will close when focus is lost)" : "Pin (keep window open when switching apps)")
                .accessibilityIdentifier("pinButton")

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
