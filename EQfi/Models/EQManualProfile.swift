//
//  EQManualProfile.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Eight-band EQ profile applied by the native system EQ engine.
struct EQManualProfile: Codable, Sendable, Equatable {
    var bands: [EQBand]
    var masterGain: Float
    var presetName: String?

    /// Returns a flat eight-band profile with zero gain on all bands.
    static func flat(masterGain: Float = 0) -> EQManualProfile {
        EQManualProfile(
            bands: EQBand.standardBands,
            masterGain: masterGain,
            presetName: "Flat"
        )
    }
}
