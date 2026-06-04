//
//  MultichannelStereoDownmixer.swift
//  EQfi
//
//  Created by Ahsan Minhas on 04/06/2026.
//

import AVFoundation
import CoreAudio
import Foundation

/// Downmixes multi-channel interleaved float tap audio to stereo (main L/R = channels 0 and 1).
enum MultichannelStereoDownmixer {
    /// Returns interleaved stereo samples, or `nil` when the tap is already stereo or the payload is unsupported.
    static func downmix(
        from inputData: UnsafePointer<AudioBufferList>,
        frameCount: AVAudioFrameCount,
        tapFormat: AVAudioFormat
    ) -> [Float]? {
        let inputChannels = Int(tapFormat.channelCount)
        guard inputChannels > 2 else { return nil }
        guard tapFormat.commonFormat == .pcmFormatFloat32 else { return nil }

        let frames = Int(frameCount)
        guard frames > 0 else { return nil }

        let bufferList = UnsafeMutableAudioBufferListPointer(
            UnsafeMutablePointer(mutating: inputData)
        )
        guard !bufferList.isEmpty else { return nil }

        var stereo = [Float]()
        stereo.reserveCapacity(frames * 2)

        if tapFormat.isInterleaved, let data = bufferList[0].mData {
            data.withMemoryRebound(to: Float.self, capacity: frames * inputChannels) { pointer in
                for frame in 0..<frames {
                    let base = frame * inputChannels
                    stereo.append(pointer[base])
                    stereo.append(pointer[base + 1])
                }
            }
            return stereo
        }

        guard bufferList.count >= 2,
              let left = bufferList[0].mData,
              let right = bufferList[1].mData else {
            return nil
        }
        let leftPtr = left.assumingMemoryBound(to: Float.self)
        let rightPtr = right.assumingMemoryBound(to: Float.self)
        for frame in 0..<frames {
            stereo.append(leftPtr[frame])
            stereo.append(rightPtr[frame])
        }
        return stereo
    }
}
