//
//  SettingsView.swift
//  Ghostly
//
//  Created by Ghostly Contributors
//

import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @Bindable var settingsManager: SettingsManager

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Settings")
                .font(.system(size: 16, weight: .semibold, design: .default))
                .foregroundStyle(Color.catText)
                .accessibilityIdentifier("settingsTitle")

            // Launch at Login with icon
            HStack(spacing: 12) {
                Image(systemName: "power.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.catTeal)
                    .frame(width: 20)

                Toggle("Launch at Login", isOn: $settingsManager.launchAtLogin)
                    .toggleStyle(.switch)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.catText)
                    .tint(Color.catLavender)
                    .accessibilityIdentifier("launchAtLoginToggle")
            }

            // Keyboard Shortcuts section
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "command.circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.catPeach)
                        .frame(width: 20)

                    Text("Keyboard Shortcuts")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.catSubtext)
                }

                VStack(alignment: .leading, spacing: 8) {
                    ShortcutRow(label: "Toggle Ghostly", shortcut: .toggleGhostly, accessibilityId: "shortcutRecorder")
                    ShortcutRow(label: "New Tab", shortcut: .newTab, accessibilityId: "newTabShortcutRecorder")
                    ShortcutRow(label: "Close Tab", shortcut: .closeTab, accessibilityId: "closeTabShortcutRecorder")
                }
                .padding(.leading, 32)
            }

            Spacer()

            // Version number at bottom
            HStack {
                Spacer()
                Text("v\(Bundle.main.appVersion)")
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.catOverlay.opacity(0.5))
            }
        }
        .frame(width: 260, height: 340)
        .padding(16)
        .background(Color.catBase.opacity(0.7))
        .innerGlow(.catLavender, radius: 6, intensity: 0.2)
        .catShadow(color: .catCrust, radius: 12, y: 6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

// MARK: - Bundle Extension for Version

extension Bundle {
    var appVersion: String {
        (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
    }
}

// MARK: - Shortcut Row

private struct ShortcutRow: View {
    let label: String
    let shortcut: KeyboardShortcuts.Name
    let accessibilityId: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.catOverlay)
                .frame(width: 80, alignment: .leading)
            KeyboardShortcuts.Recorder("", name: shortcut)
                .accessibilityIdentifier(accessibilityId)
        }
    }
}

#Preview {
    SettingsView(settingsManager: SettingsManager())
}
