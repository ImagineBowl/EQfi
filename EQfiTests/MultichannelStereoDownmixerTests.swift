//
//  MultichannelStereoDownmixerTests.swift
//  EQfiTests
//
//  Created by Ahsan Minhas on 04/06/2026.
//

import AVFoundation
import CoreAudio
import XCTest
@testable import EQfi

final class MultichannelStereoDownmixerTests: XCTestCase {
    func testDownmixesSixChannelInterleavedToStereo() throws {
        let tag = AudioChannelLayoutTag(kAudioChannelLayoutTag_DiscreteInOrder | 6)
        var layout = AudioChannelLayout()
        layout.mChannelLayoutTag = tag
        layout.mChannelBitmap = AudioChannelBitmap(rawValue: 0)
        layout.mNumberChannelDescriptions = 0
        let channelLayout = withUnsafePointer(to: &layout) { AVAudioChannelLayout(layout: $0) }
        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 44_100,
            interleaved: true,
            channelLayout: channelLayout
        )

        let frames = 4
        var samples = [Float]()
        for frame in 0..<frames {
            for channel in 0..<6 {
                samples.append(Float(frame * 10 + channel))
            }
        }

        let bufferList = try makeInterleavedBufferList(samples: samples, frames: frames, channels: 6)
        defer { free(bufferList.unsafeMutablePointer) }

        let stereo = MultichannelStereoDownmixer.downmix(
            from: bufferList.pointer,
            frameCount: AVAudioFrameCount(frames),
            tapFormat: format
        )
        XCTAssertEqual(stereo?.count, frames * 2)
        XCTAssertEqual(stereo?[0], 0)
        XCTAssertEqual(stereo?[1], 1)
        XCTAssertEqual(stereo?[2], 10)
        XCTAssertEqual(stereo?[3], 11)
    }

    private func makeInterleavedBufferList(
        samples: [Float],
        frames: Int,
        channels: Int
    ) throws -> (pointer: UnsafePointer<AudioBufferList>, unsafeMutablePointer: UnsafeMutablePointer<AudioBufferList>) {
        let byteSize = samples.count * MemoryLayout<Float>.size
        let bufferListPointer = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: 1)
        bufferListPointer.pointee.mNumberBuffers = 1
        let audioBuffer = AudioBuffer(
            mNumberChannels: UInt32(channels),
            mDataByteSize: UInt32(byteSize),
            mData: UnsafeMutableRawPointer.allocate(byteCount: byteSize, alignment: MemoryLayout<Float>.alignment)
        )
        bufferListPointer.pointee.mBuffers = audioBuffer
        samples.withUnsafeBufferPointer { source in
            guard let base = source.baseAddress else { return }
            audioBuffer.mData?.copyMemory(from: base, byteCount: byteSize)
        }
        return (UnsafePointer(bufferListPointer), bufferListPointer)
    }
}
