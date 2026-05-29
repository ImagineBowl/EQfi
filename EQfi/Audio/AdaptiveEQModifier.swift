//
//  AdaptiveEQModifier.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Applies subtle real-time adjustments on top of a genre/base EQ profile.
struct AdaptiveEQModifier {
    private let maxDelta = Constants.AdaptiveEQ.maxBandDeltaDB

    /// Returns eight-band gains combining the base profile with adaptive offsets.
    func modifiedBands(base: EQManualProfile, features: AudioFeatures) -> [Float] {
        let deltas = bandDeltas(for: features)
        return zip(base.bands, deltas).map { band, delta in
            clamp(band.gain + delta, min: Constants.ManualEQ.bandGainMin, max: Constants.ManualEQ.bandGainMax)
        }
    }

    private func bandDeltas(for features: AudioFeatures) -> [Float] {
        var deltas = Array(repeating: Float(0), count: Constants.SystemEQ.bandCount)

        if features.bassEnergy < 0.18 {
            deltas[0] += maxDelta * 0.8
            deltas[1] += maxDelta * 0.6
        } else if features.bassEnergy > 0.42 {
            deltas[1] -= maxDelta * 0.4
            deltas[2] -= maxDelta * 0.3
        }

        if features.harshness > 0.35 {
            deltas[4] -= maxDelta * 0.5
            deltas[5] -= maxDelta * 0.7
            deltas[6] -= maxDelta * 0.8
        }

        if features.spectralCentroidHz < 1_800, features.bassEnergy > 0.3 {
            deltas[2] -= maxDelta * 0.5
            deltas[3] -= maxDelta * 0.4
        }

        if features.trebleEnergy < 0.12 {
            deltas[6] += maxDelta * 0.5
            deltas[7] += maxDelta * 0.6
        } else if features.trebleEnergy > 0.35 {
            deltas[7] -= maxDelta * 0.4
        }

        if features.dynamicRangeDB > 18 {
            deltas = deltas.map { $0 * 0.6 }
        }

        if features.rmsLoudnessDB > -8 {
            deltas = deltas.map { $0 * 0.5 }
        }

        return deltas
    }

    private func clamp(_ value: Float, min: Float, max: Float) -> Float {
        Swift.min(Swift.max(value, min), max)
    }
}
