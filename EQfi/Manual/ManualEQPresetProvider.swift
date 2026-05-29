//
//  ManualEQPresetProvider.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Supplies built-in eight-band EQ presets for manual mode.
struct ManualEQPresetProvider {
    /// Returns all built-in presets in display order.
    static func builtInPresets() -> [EQPreset] {
        [
            flat, rock, pop, jazz, classical, hiphop, podcast,
            bassBoost, trebleBoost, vocalBoost, nightMode
        ]
    }

    /// Returns a built-in preset by name, if it exists.
    static func preset(named name: String) -> EQPreset? {
        builtInPresets().first { $0.name == name }
    }

    private static func make(_ name: String, gains: [Float], master: Float = 0) -> EQPreset {
        let bands = zip(EQBand.standardBands, gains).map { band, gain in
            EQBand(frequency: band.frequency, label: band.label, gain: gain)
        }
        return EQPreset(name: name, bands: bands, masterGain: master, isBuiltIn: true)
    }

    private static let flat = make("Flat", gains: [0, 0, 0, 0, 0, 0, 0, 0])
    private static let rock = make("Rock", gains: [4, 3, 2, 0, -1, 0, 3, 4])
    private static let pop = make("Pop", gains: [1, 2, 2, 1, 0, 1, 2, 3])
    private static let jazz = make("Jazz", gains: [2, 2, 1, 2, -1, -1, 2, 2])
    private static let classical = make("Classical", gains: [0, 0, 0, 1, 1, 0, 2, 3])
    private static let hiphop = make("Hip-Hop", gains: [6, 5, 3, 1, -1, 0, 2, 1])
    private static let podcast = make("Podcast", gains: [-4, -2, 0, 1, 4, 4, 2, 1])
    private static let bassBoost = make("Bass Boost", gains: [6, 5, 4, 1, 0, 0, 0, 0])
    private static let trebleBoost = make("Treble Boost", gains: [0, 0, 0, 0, 0, 2, 5, 6])
    private static let vocalBoost = make("Vocal Boost", gains: [-2, -1, 0, 2, 4, 3, 1, 0])
    private static let nightMode = make("Night Mode", gains: [-3, -2, -1, 1, 2, 2, 0, -2])
}
