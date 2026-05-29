//
//  EQParameterSmoother.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Exponential smoothing for EQ band gains to avoid zipper noise and clicks.
final class EQParameterSmoother: @unchecked Sendable {
    private var current: [Float]
    private let smoothingFactor: Float

    init(
        bandCount: Int = Constants.SystemEQ.bandCount,
        smoothingFactor: Float = Constants.AdaptiveEQ.smoothingFactor
    ) {
        current = Array(repeating: 0, count: bandCount)
        self.smoothingFactor = smoothingFactor
    }

    /// Resets the smoother to the provided band gains.
    func reset(to gains: [Float]) {
        current = gains
    }

    /// Steps toward the target gains and returns the smoothed values.
    func step(toward target: [Float]) -> [Float] {
        for index in current.indices where target.indices.contains(index) {
            let delta = target[index] - current[index]
            current[index] += delta * smoothingFactor
        }
        return current
    }
}
