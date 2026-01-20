//
//  HeaderView.swift
//  Ghostly
//
//  Created by Jay Stakelon on 1/30/21.
//

import SwiftUI

struct HeaderView: View {
    var settingsManager: SettingsManager

    var body: some View {
        HStack {
            Text("Ghostly")
                .font(Font.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color.catText)
                .accessibilityIdentifier("headerTitle")
            Spacer()
            DropdownMenuView(settingsManager: settingsManager)
                .frame(width: 24, height: 24)
                .glassEffect(.regular.interactive(), in: .circle)
                .accessibilityIdentifier("menuButton")
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 12)
    }
}
