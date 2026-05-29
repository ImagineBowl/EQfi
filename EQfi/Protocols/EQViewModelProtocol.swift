//
//  EQViewModelProtocol.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Observable UI state consumed by menubar and panel views.
@MainActor
protocol EQViewModelProtocol: AnyObject, Observable {
    var currentTrack: TrackInfo? { get }
    var detectedGenres: [String] { get }
    var currentProfile: EQProfile? { get }
    var manualProfile: EQManualProfile? { get }
    var pipelineState: EQState { get }
    var mode: EQfiMode { get }
    var isEQEnabled: Bool { get }
    var ollamaStatus: ServiceConnectionStatus { get }
    var systemEQStatus: ServiceConnectionStatus { get }
    var errorMessage: String? { get }

    /// Toggles EQ application on or off.
    func toggleEQEnabled()

    /// Switches between AI and manual operating modes.
    func setMode(_ mode: EQfiMode)

    /// Starts all background monitoring and pipeline tasks.
    func start()

    /// Stops all background monitoring and pipeline tasks.
    func stop()
}
