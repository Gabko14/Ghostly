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

            // Global Shortcut with icon
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "command.circle")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.catPeach)
                        .frame(width: 20)

                    Text("Global Shortcut")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.catSubtext)
                }

                KeyboardShortcuts.Recorder("", name: .toggleGhostly)
                    .padding(.leading, 32)
                    .accessibilityIdentifier("shortcutRecorder")
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
        .frame(width: 260, height: 280)
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

#Preview {
    SettingsView(settingsManager: SettingsManager())
}
