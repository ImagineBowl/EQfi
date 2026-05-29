//
//  EQBandConfigurator.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import AVFoundation
import Foundation

/// Maps EQManualProfile bands onto an AVAudioUnitEQ instance.
struct EQBandConfigurator {
    /// Applies eight-band gains and master volume to the EQ unit.
    static func apply(profile: EQManualProfile, to eqUnit: AVAudioUnitEQ, mixer: AVAudioMixerNode) {
        let bands = eqUnit.bands
        for index in bands.indices {
            let source = profile.bands.indices.contains(index) ? profile.bands[index] : EQBand.standardBands[index]
            configureBand(bands[index], from: source)
        }
        mixer.outputVolume = masterVolumeLinear(for: profile.masterGain)
    }

    /// Updates only band gains and master volume for smooth adaptive changes.
    static func applyGains(
        _ gains: [Float],
        masterGain: Float,
        to eqUnit: AVAudioUnitEQ,
        mixer: AVAudioMixerNode
    ) {
        let bands = eqUnit.bands
        for index in bands.indices {
            let gain = gains.indices.contains(index) ? gains[index] : 0
            bands[index].gain = gain
        }
        mixer.outputVolume = masterVolumeLinear(for: masterGain)
    }

    private static func configureBand(_ band: AVAudioUnitEQFilterParameters, from source: EQBand) {
        band.filterType = .parametric
        band.frequency = Float(source.frequency)
        band.bandwidth = 1.0
        band.gain = source.gain
        band.bypass = false
    }

    private static func masterVolumeLinear(for gainDB: Float) -> Float {
        pow(10, gainDB / 20)
    }
}
