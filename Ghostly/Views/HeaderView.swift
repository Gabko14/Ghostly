//
//  HeaderView.swift
//  Ghostly
//
//  Created by Jay Stakelon on 1/30/21.
//

import SwiftUI

struct HeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Ghostly")
                    .font(Font.system(size: 12, weight: .bold, design: .rounded))
                    .accessibilityIdentifier("headerTitle")
                Spacer()
                DropdownMenuView()
                    .frame(width: 24, height: 24)
                    .accessibilityIdentifier("menuButton")
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 12)
            Divider().background(Color.gray.opacity(0.1))
        }.background(Color(.windowBackgroundColor))
    }
}
