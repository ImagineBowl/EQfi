//
//  EQPreset.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Named EQ preset containing band gains and optional master gain.
struct EQPreset: Codable, Sendable, Equatable, Identifiable {
    let name: String
    var bands: [EQBand]
    var masterGain: Float
    let isBuiltIn: Bool

    var id: String { name }

    /// Creates a custom preset from the current manual EQ state.
    static func custom(name: String, bands: [EQBand], masterGain: Float) -> EQPreset {
        EQPreset(name: name, bands: bands, masterGain: masterGain, isBuiltIn: false)
    }
}
