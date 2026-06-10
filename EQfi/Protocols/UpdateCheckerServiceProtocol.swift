//
//  UpdateCheckerServiceProtocol.swift
//  EQfi
//
//  Created by Ahsan Minhas on 11/06/2026.
//

import Foundation

/// Checks GitHub Releases for newer EQfi versions.
protocol UpdateCheckerServiceProtocol: Sendable {
    /// Returns update info when a newer release is available, otherwise `nil`.
    func checkForUpdateIfNeeded() async -> AppUpdateInfo?

    /// Records that the user dismissed a specific release version.
    func dismiss(version: String)
}
