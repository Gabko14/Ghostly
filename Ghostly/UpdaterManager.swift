//
//  UpdaterManager.swift
//  Ghostly
//
//  Created by Ghostly Contributors
//

import Combine
import OSLog
@preconcurrency import Sparkle

@MainActor
@Observable
final class UpdaterManager {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.ghostly.Ghostly",
        category: "UpdaterManager"
    )

    private let updaterController: SPUStandardUpdaterController
    private var cancellable: AnyCancellable?

    var canCheckForUpdates = false

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        cancellable = updaterController.updater.publisher(for: \.canCheckForUpdates)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.canCheckForUpdates = value
            }
        startUpdaterIfConfigured()
    }

    func checkForUpdates() {
        updaterController.updater.checkForUpdates()
    }

    var automaticallyChecksForUpdates: Bool {
        get { updaterController.updater.automaticallyChecksForUpdates }
        set { updaterController.updater.automaticallyChecksForUpdates = newValue }
    }

    private func startUpdaterIfConfigured() {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String,
              !key.isEmpty, key != "PLACEHOLDER" else {
            logger.info("Sparkle updater not started: EdDSA public key not configured")
            return
        }
        do {
            try updaterController.updater.start()
        } catch {
            logger.error("Failed to start Sparkle updater: \(error.localizedDescription)")
        }
    }
}
