//
//  NowPlayingServiceProtocol.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Detects the currently playing track and notifies on changes.
protocol NowPlayingServiceProtocol: AnyObject, Sendable {
    /// Callback invoked when title or artist changes.
    var onTrackChange: (@Sendable (TrackInfo) -> Void)? { get set }

    /// Returns the currently playing track, if any.
    func currentTrack() async throws -> TrackInfo?

    /// Starts polling for track changes at the given interval.
    func startPolling(interval: TimeInterval)

    /// Stops active track polling.
    func stopPolling()
}
