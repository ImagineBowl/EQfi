//
//  EQProfileBridge.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Converts between five-band AI profiles and eight-band system EQ payloads.
struct EQProfileBridge {
    /// Maps a five-band AI profile to an eight-band manual profile using interpolated gains.
    static func toEightBand(_ profile: EQProfile, masterGain: Float = 0) -> EQManualProfile {
        let bands = [
            EQBand(frequency: 32, label: "Sub Bass", gain: profile.subBass),
            EQBand(
                frequency: 64,
                label: "Bass",
                gain: interpolate(profile.subBass, profile.bass, amount: 0.35)
            ),
            EQBand(
                frequency: 125,
                label: "Upper Bass",
                gain: interpolate(profile.subBass, profile.bass, amount: 0.65)
            ),
            EQBand(
                frequency: 250,
                label: "Low Midrange",
                gain: interpolate(profile.bass, profile.midrange, amount: 0.35)
            ),
            EQBand(frequency: 500, label: "Midrange", gain: profile.midrange),
            EQBand(
                frequency: 1_000,
                label: "Upper Midrange",
                gain: interpolate(profile.midrange, profile.presence, amount: 0.65)
            ),
            EQBand(
                frequency: 8_000,
                label: "Presence",
                gain: interpolate(profile.presence, profile.brilliance, amount: 0.35)
            ),
            EQBand(
                frequency: 16_000,
                label: "Brilliance",
                gain: interpolate(profile.presence, profile.brilliance, amount: 0.65)
            )
        ]
        return EQManualProfile(
            bands: bands,
            masterGain: masterGain,
            presetName: profile.presetName
        )
    }

    private static func interpolate(_ start: Float, _ end: Float, amount: Float) -> Float {
        start + ((end - start) * amount)
    }
}
