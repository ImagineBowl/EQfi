//
//  AppDelegate.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import AppKit

/// Application delegate that starts EQfi services at launch.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) lazy var dependencies = AppDependencies.make()

    /// Starts ViewModel monitoring when the app finishes launching.
    func applicationDidFinishLaunching(_ notification: Notification) {
        dependencies.viewModel.start()
        if dependencies.viewModel.showOnboarding {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }

    /// Stops services before the app terminates.
    func applicationWillTerminate(_ notification: Notification) {
        dependencies.viewModel.stop()
    }
}
