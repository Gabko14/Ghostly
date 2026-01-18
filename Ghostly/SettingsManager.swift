//
//  SettingsManager.swift
//  Ghostly
//
//  Created by Ghostly Contributors
//

import Foundation
import ServiceManagement

@Observable
@MainActor
class SettingsManager {
    var isSettingsOpen: Bool = false
    var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            updateLaunchAtLogin()
        }
    }

    init() {
        // Check actual SMAppService status rather than just UserDefaults
        // This ensures UI reflects reality if user changed setting via System Settings
        let status = SMAppService.mainApp.status
        self.launchAtLogin = (status == .enabled)
        UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
    }

    func showSettings() {
        self.isSettingsOpen = true
    }

    func hideSettings() {
        self.isSettingsOpen = false
    }

    private func updateLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Silently handle error - user can toggle again if needed
        }
    }
}
