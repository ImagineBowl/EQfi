//
//  EQOrchestratorProtocol.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Coordinates the AI pipeline from track detection through EQ application.
protocol EQOrchestratorProtocol: AnyObject, Sendable {
    /// Current pipeline lifecycle state.
    var currentState: EQState { get }

    /// Callback invoked when pipeline state changes.
    var onStateChange: (@Sendable (EQState) -> Void)? { get set }

    /// Callback invoked when a new EQ profile has been applied.
    var onProfileApplied: (@Sendable (EQPipelineResult) -> Void)? { get set }

    /// Starts listening for track changes and running the AI pipeline.
    func startListening()

    /// Stops listening and cancels in-flight pipeline work.
    func stopListening()

    /// Immediately re-runs the pipeline for the current track.
    func refreshCurrentTrack() async

    /// Processes a detected track through the full AI pipeline.
    func processTrack(_ track: TrackInfo) async

    /// Re-runs the pipeline even when EQ is disabled so the UI can refresh.
    func retryCurrentTrack() async

    /// Enables or disables automatic EQ application.
    func setEnabled(_ enabled: Bool)
}
