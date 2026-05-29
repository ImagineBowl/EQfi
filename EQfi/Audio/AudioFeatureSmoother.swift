//
//  AudioFeatureSmoother.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Exponential moving average smoothing for adaptive analysis features.
struct AudioFeatureSmoother {
    private var state: AudioFeatures?
    private let factor: Float

    init(smoothingFactor: Float = Constants.AdaptiveEQ.featureSmoothingFactor) {
        factor = smoothingFactor
    }

    /// Returns smoothed features and resets when given a nil input.
    mutating func process(_ raw: AudioFeatures) -> AudioFeatures {
        guard let current = state else {
            state = raw
            return raw
        }
        let smoothed = AudioFeatures(
            bassEnergy: interpolate(current.bassEnergy, raw.bassEnergy),
            trebleEnergy: interpolate(current.trebleEnergy, raw.trebleEnergy),
            rmsLoudnessDB: interpolate(current.rmsLoudnessDB, raw.rmsLoudnessDB),
            spectralCentroidHz: interpolate(current.spectralCentroidHz, raw.spectralCentroidHz),
            dynamicRangeDB: interpolate(current.dynamicRangeDB, raw.dynamicRangeDB),
            harshness: interpolate(current.harshness, raw.harshness),
            capturedAt: raw.capturedAt
        )
        state = smoothed
        return smoothed
    }

    mutating func reset() {
        state = nil
    }

    private func interpolate(_ current: Float, _ raw: Float) -> Float {
        current + ((raw - current) * factor)
    }
}
