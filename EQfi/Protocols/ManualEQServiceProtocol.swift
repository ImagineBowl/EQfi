//
//  ManualEQServiceProtocol.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Applies manual eight-band EQ changes with debouncing.
protocol ManualEQServiceProtocol: Sendable {
    /// Applies bands immediately (presets, reset, mode switch).
    func applyBands(_ bands: [EQBand], masterGain: Float) async throws

    /// Applies bands after a debounce delay for live slider movement.
    func applyBandsDebounced(_ bands: [EQBand], masterGain: Float)

    /// Returns the last profile successfully applied.
    func currentProfile() -> EQManualProfile?
}
