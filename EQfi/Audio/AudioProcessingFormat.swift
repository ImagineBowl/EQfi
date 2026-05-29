//
//  AudioProcessingFormat.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import AVFoundation
import Foundation

/// Builds AVAudioEngine-compatible formats from tap stream descriptions.
enum AudioProcessingFormat {
    /// Returns a stereo float format suitable for AVAudioUnitEQ processing.
    static func processingFormat(tapFormat: AVAudioFormat, outputFormat: AVAudioFormat) throws -> AVAudioFormat {
        if tapFormat.commonFormat == .pcmFormatFloat32,
           tapFormat.channelCount == Constants.SystemEQ.channelCount {
            return tapFormat
        }

        let sampleRate = resolvedSampleRate(tap: tapFormat, output: outputFormat)
        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: Constants.SystemEQ.channelCount
        ) else {
            throw SystemEQError.engineStartFailed("Unable to create processing format.")
        }
        return format
    }

    private static func resolvedSampleRate(tap: AVAudioFormat, output: AVAudioFormat) -> Double {
        if tap.sampleRate > 0 { return tap.sampleRate }
        if output.sampleRate > 0 { return output.sampleRate }
        return Constants.SystemEQ.defaultSampleRate
    }
}
