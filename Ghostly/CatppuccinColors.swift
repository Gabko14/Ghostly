//
//  CatppuccinColors.swift
//  Ghostly
//
//  Catppuccin Mocha color palette
//  https://catppuccin.com/palette
//

import SwiftUI

extension Color {
    // MARK: - Backgrounds
    /// Main background color - used for popover background
    static let catBase = Color(red: 30/255, green: 30/255, blue: 46/255)
    /// Darker background - available for sidebars/panels
    static let catMantle = Color(red: 24/255, green: 24/255, blue: 37/255)
    /// Darkest background - used for modal overlays
    static let catCrust = Color(red: 17/255, green: 17/255, blue: 27/255)
    /// Surface color - available for elevated elements
    static let catSurface = Color(red: 49/255, green: 50/255, blue: 68/255)

    // MARK: - Text
    /// Primary text color
    static let catText = Color(red: 205/255, green: 214/255, blue: 244/255)
    /// Secondary text color - used for labels
    static let catSubtext = Color(red: 166/255, green: 173/255, blue: 200/255)
    /// Muted text color - used for placeholders
    static let catOverlay = Color(red: 108/255, green: 112/255, blue: 134/255)

    // MARK: - Accents
    /// Primary accent color - used for icons, selection, toggles
    static let catLavender = Color(red: 180/255, green: 190/255, blue: 254/255)

    // MARK: - Extended Accents (Catppuccin Mocha)
    /// Pink accent
    static let catPink = Color(red: 245/255, green: 194/255, blue: 231/255)
    /// Mauve accent
    static let catMauve = Color(red: 203/255, green: 166/255, blue: 247/255)
    /// Blue accent
    static let catBlue = Color(red: 137/255, green: 180/255, blue: 250/255)
    /// Teal accent
    static let catTeal = Color(red: 148/255, green: 226/255, blue: 213/255)
    /// Peach accent
    static let catPeach = Color(red: 250/255, green: 179/255, blue: 135/255)

    // MARK: - Surface Variants (for depth)
    /// Surface level 0
    static let catSurface0 = Color(red: 49/255, green: 50/255, blue: 68/255)
    /// Surface level 1
    static let catSurface1 = Color(red: 69/255, green: 71/255, blue: 90/255)
    /// Surface level 2
    static let catSurface2 = Color(red: 88/255, green: 91/255, blue: 112/255)
}
