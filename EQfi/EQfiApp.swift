//
//  EQfiApp.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import SwiftUI

@main
struct EQfiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(
                viewModel: appDelegate.dependencies.viewModel,
                keychain: appDelegate.dependencies.keychain
            )
        } label: {
            MenuBarIconView(viewModel: appDelegate.dependencies.viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Menubar icon that updates when operating mode changes.
private struct MenuBarIconView: View {
    @Bindable var viewModel: EQViewModel

    var body: some View {
        Image(systemName: viewModel.mode.menuBarSymbolName)
    }
}
