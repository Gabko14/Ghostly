//
//  TabBarView.swift
//  Ghostly
//
//  Chrome-style tab bar for managing multiple text documents
//

import SwiftUI

struct TabBarView: View {
    @Bindable var tabManager: TabManager

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(tabManager.tabs) { tab in
                        TabItemView(
                            tab: tab,
                            isActive: tab.id == tabManager.activeTabId,
                            onSelect: { tabManager.selectTab(tab.id) },
                            onClose: { tabManager.closeTab(tab.id) }
                        )
                    }

                    // Plus button to add new tab
                    Button {
                        tabManager.newTab()
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.catOverlay)
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .opacity(0.7)
                    .accessibilityIdentifier("newTabButton")
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .frame(height: 34)

            // Subtle divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.catSurface0.opacity(0),
                            Color.catSurface0.opacity(0.4),
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

// MARK: - Tab Item

private struct TabItemView: View {
    let tab: GhostlyTab
    let isActive: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 6) {
                Text(tab.title)
                    .font(.system(size: 11, weight: isActive ? .medium : .regular))
                    .foregroundStyle(isActive ? Color.catText : Color.catSubtext)
                    .lineLimit(1)

                // Close button - visible on hover or when active
                if isHovered || isActive {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(Color.catOverlay)
                            .frame(width: 14, height: 14)
                            .background(
                                Circle()
                                    .fill(Color.catSurface1.opacity(isHovered ? 0.8 : 0))
                            )
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isActive ? Color.catSurface0.opacity(0.6) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isActive)
    }
}

#Preview {
    VStack {
        TabBarView(tabManager: {
            let manager = TabManager()
            manager.newTab()
            return manager
        }())
    }
    .frame(width: 400)
    .background(Color.catBase)
}
