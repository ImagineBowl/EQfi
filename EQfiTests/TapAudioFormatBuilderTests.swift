//
//  TapAudioFormatBuilderTests.swift
//  EQfiTests
//
//  Created by Ahsan Minhas on 04/06/2026.
//

import AVFoundation
import CoreAudio
import XCTest
@testable import EQfi

final class TapAudioFormatBuilderTests: XCTestCase {
    /// Komplete Audio 6 default tap ASBD reported by Core Audio (6ch float32 @ 44.1 kHz).
    private func kompleteAudio6ASBD() -> AudioStreamBasicDescription {
        var asbd = AudioStreamBasicDescription()
        asbd.mSampleRate = 44_100
        asbd.mFormatID = kAudioFormatLinearPCM
        asbd.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked
        asbd.mBytesPerPacket = 24
        asbd.mFramesPerPacket = 1
        asbd.mBytesPerFrame = 24
        asbd.mChannelsPerFrame = 6
        asbd.mBitsPerChannel = 32
        return asbd
    }

    func testKompleteAudio6FormatResolves() {
        let format = TapAudioFormatBuilder.format(from: kompleteAudio6ASBD())
        XCTAssertNotNil(format)
        XCTAssertEqual(format?.sampleRate ?? 0, 44_100, accuracy: 0.1)
        XCTAssertEqual(format?.channelCount, 6)
        XCTAssertEqual(format?.commonFormat, .pcmFormatFloat32)
        XCTAssertTrue(format?.isInterleaved ?? false)
    }

    func testKompleteAudio6FormatConvertsToStereo() {
        let asbd = kompleteAudio6ASBD()
        guard let tapFormat = TapAudioFormatBuilder.format(from: asbd) else {
            XCTFail("Expected tap format")
            return
        }
        guard let stereoFormat = AVAudioFormat(
            standardFormatWithSampleRate: tapFormat.sampleRate,
            channels: Constants.SystemEQ.channelCount
        ) else {
            XCTFail("Expected stereo format")
            return
        }
        XCTAssertNotNil(AVAudioConverter(from: tapFormat, to: stereoFormat))
    }
}
