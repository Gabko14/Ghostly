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
                .font(.headline)
                .foregroundStyle(.primary)
                .accessibilityIdentifier("settingsTitle")

            Toggle("Launch at Login", isOn: $settingsManager.launchAtLogin)
                .toggleStyle(.switch)
                .foregroundStyle(.primary)
                .accessibilityIdentifier("launchAtLoginToggle")

            VStack(alignment: .leading, spacing: 8) {
                Text("Global Shortcut")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                KeyboardShortcuts.Recorder("", name: .toggleGhostly)
                    .accessibilityIdentifier("shortcutRecorder")
            }

            Spacer()
        }
        .frame(width: 240, height: 280)
        .padding(12)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    SettingsView(settingsManager: SettingsManager())
}
