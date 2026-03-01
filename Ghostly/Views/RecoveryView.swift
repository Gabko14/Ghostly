//
//  RecoveryView.swift
//  Ghostly
//

import SwiftUI

struct RecoveryView: View {
    var appState: AppState
    let recoveryState: RecoveryState

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Notes Recovery")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.catText)

            Text(summaryText)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.catSubtext)
                .fixedSize(horizontal: false, vertical: true)

            if let backupURL {
                Text("Latest backup: \(backupURL.path)")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.catOverlay)
                    .textSelection(.enabled)
            }

            if let quarantineURL {
                Text("Quarantined data: \(quarantineURL.path)")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.catOverlay)
                    .textSelection(.enabled)
            }

            if !appState.recoveryNotice.isEmpty {
                Text(appState.recoveryNotice)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.catPeach)
            }

            HStack(spacing: 10) {
                Button("Restore Backup") {
                    Task { await appState.restoreFromLatestBackup() }
                }
                .disabled(backupURL == nil)

                Button("Export Recovery Bundle") {
                    Task { await appState.exportRecoveryBundle() }
                }

                Button("Start Fresh") {
                    Task { await appState.startFresh() }
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.catLavender)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(20)
        .background(Color.catBase.opacity(0.7))
    }

    private var summaryText: String {
        switch recoveryState {
        case let .storeUnreadable(summary, _, _):
            return summary
        case let .migrationFailed(summary, _):
            return summary
        case .restoreInProgress:
            return "Ghostly is restoring your latest good backup."
        case let .freshStartAvailable(summary, _):
            return summary
        }
    }

    private var backupURL: URL? {
        switch recoveryState {
        case let .storeUnreadable(_, _, backupURL):
            return backupURL
        case let .migrationFailed(_, legacyBackupURL):
            return legacyBackupURL
        case .restoreInProgress, .freshStartAvailable:
            return nil
        }
    }

    private var quarantineURL: URL? {
        switch recoveryState {
        case let .storeUnreadable(_, quarantineURL, _):
            return quarantineURL
        case let .freshStartAvailable(_, quarantineURL):
            return quarantineURL
        case .migrationFailed, .restoreInProgress:
            return nil
        }
    }
}
