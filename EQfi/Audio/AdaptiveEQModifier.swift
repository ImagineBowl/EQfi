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
    private let maxStackedDelta = Constants.AdaptiveEQ.maxStackedDeltaDB

    /// Returns eight-band gains combining the base profile with adaptive offsets.
    func modifiedBands(base: EQManualProfile, features: AudioFeatures) -> [Float] {
        let deltas = mergedDeltas(for: features)
        return zip(base.bands, deltas).map { band, delta in
            let scaled = scaleBoost(delta, baseGain: band.gain)
            return clamp(
                band.gain + scaled,
                min: Constants.ManualEQ.bandGainMin,
                max: Constants.ManualEQ.bandGainMax
            )
        }
    }

    private func mergedDeltas(for features: AudioFeatures) -> [Float] {
        var groups: [[Float]] = []
        groups.append(bassDeltas(for: features))
        groups.append(harshnessDeltas(for: features))
        groups.append(darkMixDeltas(for: features))
        groups.append(trebleDeltas(for: features))

        var merged = Array(repeating: Float(0), count: Constants.SystemEQ.bandCount)
        for group in groups {
            for index in merged.indices {
                if abs(group[index]) > abs(merged[index]) {
                    merged[index] = group[index]
                }
            }
        }

        if features.dynamicRangeDB > 18 {
            merged = merged.map { $0 * 0.6 }
        }
        if features.rmsLoudnessDB > -8 {
            merged = merged.map { $0 * 0.5 }
        }

        return merged.map { clamp($0, min: -maxStackedDelta, max: maxStackedDelta) }
    }

    private func bassDeltas(for features: AudioFeatures) -> [Float] {
        var deltas = zeroDeltas()
        if features.bassEnergy < Constants.AdaptiveEQ.bassLowThreshold {
            deltas[0] += maxDelta * 0.7
            deltas[1] += maxDelta * 0.5
        } else if features.bassEnergy > Constants.AdaptiveEQ.bassHighThreshold {
            deltas[1] -= maxDelta * 0.35
            deltas[2] -= maxDelta * 0.25
        }
        return deltas
    }

    private func harshnessDeltas(for features: AudioFeatures) -> [Float] {
        var deltas = zeroDeltas()
        guard features.harshness > Constants.AdaptiveEQ.harshnessThreshold else { return deltas }
        deltas[4] -= maxDelta * 0.4
        deltas[5] -= maxDelta * 0.55
        deltas[6] -= maxDelta * 0.6
        return deltas
    }

    private func darkMixDeltas(for features: AudioFeatures) -> [Float] {
        var deltas = zeroDeltas()
        guard features.spectralCentroidHz < Constants.AdaptiveEQ.darkCentroidHz,
              features.bassEnergy > Constants.AdaptiveEQ.darkMixBassThreshold else {
            return deltas
        }
        deltas[3] -= maxDelta * 0.3
        return deltas
    }

    private func trebleDeltas(for features: AudioFeatures) -> [Float] {
        var deltas = zeroDeltas()
        if features.trebleEnergy < Constants.AdaptiveEQ.trebleLowThreshold {
            deltas[6] += maxDelta * 0.35
            deltas[7] += maxDelta * 0.45
        } else if features.trebleEnergy > Constants.AdaptiveEQ.trebleHighThreshold {
            deltas[7] -= maxDelta * 0.3
        }
        return deltas
    }

    private func scaleBoost(_ delta: Float, baseGain: Float) -> Float {
        guard delta > 0 else { return delta }
        let headroom = Constants.ManualEQ.bandGainMax - baseGain
        guard headroom > 0 else { return 0 }
        let scale = min(1, headroom / maxDelta)
        return delta * scale
    }

    private func zeroDeltas() -> [Float] {
        Array(repeating: 0, count: Constants.SystemEQ.bandCount)
    }

    private func clamp(_ value: Float, min: Float, max: Float) -> Float {
        Swift.min(Swift.max(value, min), max)
    }
}
