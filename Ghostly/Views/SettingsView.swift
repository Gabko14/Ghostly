//
//  SettingsView.swift
//  Ghostly
//
//  Created by Ghostly Contributors
//

import SwiftUI

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

                Spacer()
            }
            .frame(width: 240, height: 240)
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
