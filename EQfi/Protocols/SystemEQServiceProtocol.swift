//
//  SystemEQServiceProtocol.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Applies system-wide equalizer settings using native Core Audio processing.
protocol SystemEQServiceProtocol: Sendable {
    /// Starts the native audio tap and EQ playback engine.
    func startEngine() async throws

    /// Stops the audio tap and EQ playback engine.
    func stopEngine() async

    /// Applies an eight-band profile to the running EQ engine.
    func applyProfile(_ profile: EQManualProfile, adaptiveEnabled: Bool) async throws

    /// Returns whether the EQ engine is actively processing audio.
    func isActive() async -> Bool
}
