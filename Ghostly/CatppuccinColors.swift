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
}
