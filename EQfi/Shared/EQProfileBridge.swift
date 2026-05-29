//
//  EQProfileBridge.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Converts between five-band AI profiles and eight-band system EQ payloads.
struct EQProfileBridge {
    /// Maps a five-band AI profile to an eight-band manual profile.
    static func toEightBand(_ profile: EQProfile, masterGain: Float = 0) -> EQManualProfile {
        let bands = [
            EQBand(frequency: 32, label: "Sub Bass", gain: profile.subBass),
            EQBand(frequency: 64, label: "Bass", gain: profile.bass),
            EQBand(frequency: 125, label: "Upper Bass", gain: profile.bass),
            EQBand(frequency: 250, label: "Low Midrange", gain: profile.midrange),
            EQBand(frequency: 500, label: "Midrange", gain: profile.midrange),
            EQBand(frequency: 1_000, label: "Upper Midrange", gain: profile.midrange),
            EQBand(frequency: 8_000, label: "Presence", gain: profile.presence),
            EQBand(frequency: 16_000, label: "Brilliance", gain: profile.brilliance)
        ]
        return EQManualProfile(
            bands: bands,
            masterGain: masterGain,
            presetName: profile.presetName
        )
    }
}
