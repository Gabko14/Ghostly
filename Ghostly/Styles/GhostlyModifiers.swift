//
//  GhostlyModifiers.swift
//  Ghostly
//
//  Custom view modifiers for the Ghostly ethereal aesthetic
//

import SwiftUI

// MARK: - Inner Glow Modifier

struct InnerGlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let intensity: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(intensity), lineWidth: 1)
                    .blur(radius: radius)
            )
    }
}

extension View {
    func innerGlow(_ color: Color = .catLavender, radius: CGFloat = 4, intensity: CGFloat = 0.3) -> some View {
        modifier(InnerGlowModifier(color: color, radius: radius, intensity: intensity))
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

// MARK: - Hover-Aware Button Style

struct GhostlyButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .brightness(configuration.isPressed ? 0.1 : (isHovered ? 0.05 : 0))
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension ButtonStyle where Self == GhostlyButtonStyle {
    static var ghostly: GhostlyButtonStyle { GhostlyButtonStyle() }
}
