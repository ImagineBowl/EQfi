//
//  AppUpdateInfo.swift
//  EQfi
//
//  Created by Ahsan Minhas on 11/06/2026.
//

import Foundation

/// Describes a newer EQfi release published on GitHub.
struct AppUpdateInfo: Sendable, Equatable {
    let version: String
    let releasePageURL: URL
    let downloadURL: URL?
    let releaseNotes: String?

    /// Returns the best URL to open when the user chooses to download an update.
    var preferredDownloadURL: URL {
        downloadURL ?? releasePageURL
    }
}
