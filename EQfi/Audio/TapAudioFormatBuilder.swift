//
//  TapAudioFormatBuilder.swift
//  EQfi
//
//  Created by Ahsan Minhas on 04/06/2026.
//

import AVFoundation
import CoreAudio
import Foundation

/// Builds `AVAudioFormat` from Core Audio tap stream descriptions.
enum TapAudioFormatBuilder {
    /// Returns an `AVAudioFormat` matching the tap ASBD, including multi-channel USB interfaces.
    static func format(from streamDescription: AudioStreamBasicDescription) -> AVAudioFormat? {
        var description = streamDescription
        if let format = AVAudioFormat(streamDescription: &description) {
            return format
        }
        return fallbackFormat(from: streamDescription)
    }

    private static func fallbackFormat(from asbd: AudioStreamBasicDescription) -> AVAudioFormat? {
        guard asbd.mFormatID == kAudioFormatLinearPCM else { return nil }
        guard asbd.mChannelsPerFrame > 0, asbd.mSampleRate > 0 else { return nil }

        let flags = asbd.mFormatFlags
        let isFloat = (flags & kAudioFormatFlagIsFloat) != 0
        let isNonInterleaved = (flags & kAudioFormatFlagIsNonInterleaved) != 0
        let interleaved = !isNonInterleaved
        let channelCount = asbd.mChannelsPerFrame

        if isFloat {
            return pcmFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: asbd.mSampleRate,
                channelCount: channelCount,
                interleaved: interleaved
            )
        }

        let isSigned = (flags & kAudioFormatFlagIsSignedInteger) != 0
        let isPacked = (flags & kAudioFormatFlagIsPacked) != 0
        guard isSigned, isPacked else { return nil }

        let commonFormat: AVAudioCommonFormat
        switch asbd.mBitsPerChannel {
        case 16:
            commonFormat = .pcmFormatInt16
        case 32:
            commonFormat = .pcmFormatInt32
        default:
            return nil
        }

        return pcmFormat(
            commonFormat: commonFormat,
            sampleRate: asbd.mSampleRate,
            channelCount: channelCount,
            interleaved: interleaved
        )
    }

    private static func pcmFormat(
        commonFormat: AVAudioCommonFormat,
        sampleRate: Double,
        channelCount: UInt32,
        interleaved: Bool
    ) -> AVAudioFormat? {
        if channelCount <= 2 {
            return AVAudioFormat(
                commonFormat: commonFormat,
                sampleRate: sampleRate,
                channels: AVAudioChannelCount(channelCount),
                interleaved: interleaved
            )
        }
        let channelLayout = discreteChannelLayout(channelCount: channelCount)
        return AVAudioFormat(
            commonFormat: commonFormat,
            sampleRate: sampleRate,
            interleaved: interleaved,
            channelLayout: channelLayout
        )
    }

    private static func discreteChannelLayout(channelCount: UInt32) -> AVAudioChannelLayout {
        let tag = AudioChannelLayoutTag(kAudioChannelLayoutTag_DiscreteInOrder | channelCount)
        var layout = AudioChannelLayout()
        layout.mChannelLayoutTag = tag
        layout.mChannelBitmap = AudioChannelBitmap(rawValue: 0)
        layout.mNumberChannelDescriptions = 0
        return withUnsafePointer(to: &layout) { AVAudioChannelLayout(layout: $0) }
    }
}
