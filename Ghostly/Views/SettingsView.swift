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
        HStack {
            Spacer()
            VStack(alignment: .leading, spacing: 24) {
                Text("Settings")
                    .font(.headline)
                    .accessibilityIdentifier("settingsTitle")

                Toggle("Launch at Login", isOn: $settingsManager.launchAtLogin)
                    .toggleStyle(.switch)
                    .accessibilityIdentifier("launchAtLoginToggle")

                VStack(alignment: .leading, spacing: 8) {
                    Text("Global Shortcut")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    KeyboardShortcuts.Recorder("", name: .toggleGhostly)
                        .accessibilityIdentifier("shortcutRecorder")
                }

                Spacer()
            }
            .frame(width: 240, height: 280)
            .padding(12)
            .background(Color(.windowBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            Spacer()
        }
    }
}

#Preview {
    SettingsView(settingsManager: SettingsManager())
}
