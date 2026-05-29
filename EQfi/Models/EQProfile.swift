//
//  EQProfile.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Five-band EQ profile produced by AI or fallback presets.
struct EQProfile: Codable, Sendable, Equatable {
    let subBass: Float
    let bass: Float
    let midrange: Float
    let presence: Float
    let brilliance: Float
    let presetName: String
    let reasoning: String?

    /// Ordered band gains for visualization in the menubar chart.
    var bandGains: [Float] {
        [subBass, bass, midrange, presence, brilliance]
    }

    /// Returns a flat profile with zero gain on all bands.
    static func flat(presetName: String = "Flat") -> EQProfile {
        EQProfile(
            subBass: 0,
            bass: 0,
            midrange: 0,
            presence: 0,
            brilliance: 0,
            presetName: presetName,
            reasoning: nil
        )
    }
}
