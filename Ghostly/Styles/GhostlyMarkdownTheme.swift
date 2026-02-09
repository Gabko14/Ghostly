//
//  GhostlyMarkdownTheme.swift
//  Ghostly
//
//  Catppuccin-themed markdown rendering for MarkdownUI.
//

@preconcurrency import MarkdownUI
import SwiftUI

extension Theme {
    @MainActor static let ghostly = Theme()
        .code {
            FontFamilyVariant(.monospaced)
            FontSize(.em(0.85))
            ForegroundColor(.catText)
            BackgroundColor(.catSurface0)
        }
        .link {
            ForegroundColor(.catBlue)
        }
        .heading1 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontWeight(.bold)
                    FontSize(.em(1.8))
                    ForegroundColor(.catLavender)
                }
                .markdownMargin(top: 24, bottom: 16)
        }
        .heading2 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontWeight(.bold)
                    FontSize(.em(1.5))
                    ForegroundColor(.catLavender)
                }
                .markdownMargin(top: 20, bottom: 12)
        }
        .heading3 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1.25))
                    ForegroundColor(.catLavender)
                }
                .markdownMargin(top: 16, bottom: 8)
        }
        .heading4 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontWeight(.semibold)
                    FontSize(.em(1.1))
                    ForegroundColor(.catLavender)
                }
                .markdownMargin(top: 12, bottom: 8)
        }
        .heading5 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontWeight(.medium)
                    FontSize(.em(1.0))
                    ForegroundColor(.catLavender)
                }
                .markdownMargin(top: 8, bottom: 4)
        }
        .heading6 { configuration in
            configuration.label
                .markdownTextStyle {
                    FontWeight(.medium)
                    FontSize(.em(0.9))
                    ForegroundColor(.catLavender)
                }
                .markdownMargin(top: 8, bottom: 4)
        }
        .paragraph { configuration in
            configuration.label
                .relativeLineSpacing(.em(0.25))
                .markdownMargin(top: 0, bottom: 12)
        }
        .codeBlock { configuration in
            configuration.label
                .markdownTextStyle {
                    FontFamilyVariant(.monospaced)
                    FontSize(.em(0.85))
                }
                .padding(12)
                .background(Color.catSurface0)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .markdownMargin(top: 8, bottom: 8)
        }
        .blockquote { configuration in
            configuration.label
                .padding(.leading, 12)
                .padding(.vertical, 4)
                .markdownTextStyle {
                    ForegroundColor(.catSubtext)
                }
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Color.catOverlay)
                        .frame(width: 3)
                }
                .background(Color.catMantle)
                .markdownMargin(top: 8, bottom: 8)
        }
        .listItem { configuration in
            configuration.label
                .markdownMargin(top: .em(0.25))
        }
}
