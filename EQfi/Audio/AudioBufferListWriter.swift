//
//  AudioBufferListWriter.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import AVFoundation
import CoreAudio
import Foundation

/// Writes PCM samples into Core Audio IOProc output buffers.
enum AudioBufferListWriter {
    /// Copies a PCM buffer into an output AudioBufferList.
    static func write(pcmBuffer: AVAudioPCMBuffer, to outputData: UnsafeMutablePointer<AudioBufferList>) {
        guard let channelData = pcmBuffer.floatChannelData else {
            zeroFill(outputData)
            return
        }

        let bufferList = UnsafeMutableAudioBufferListPointer(outputData)
        let frameCount = Int(pcmBuffer.frameLength)
        let channelCount = Int(pcmBuffer.format.channelCount)
        guard frameCount > 0, channelCount > 0 else {
            zeroFill(outputData)
            return
        }

        if pcmBuffer.format.isInterleaved, let destination = bufferList.first?.mData {
            let byteCount = min(
                Int(bufferList[0].mDataByteSize),
                frameCount * channelCount * MemoryLayout<Float>.size
            )
            memcpy(destination, channelData[0], byteCount)
            return
        }

        for channel in 0..<min(channelCount, bufferList.count) {
            guard let destination = bufferList[channel].mData else { continue }
            let byteCount = min(
                Int(bufferList[channel].mDataByteSize),
                frameCount * MemoryLayout<Float>.size
            )
            memcpy(destination, channelData[channel], byteCount)
        }
    }

    /// Zero-fills every buffer in the output AudioBufferList.
    static func zeroFill(_ outputData: UnsafeMutablePointer<AudioBufferList>) {
        let bufferList = UnsafeMutableAudioBufferListPointer(outputData)
        for buffer in bufferList {
            guard let data = buffer.mData else { continue }
            memset(data, 0, Int(buffer.mDataByteSize))
        }
    }

    /// Returns the frame count for a float output buffer list.
    static func frameCount(
        for outputData: UnsafeMutablePointer<AudioBufferList>,
        channelCount: Int
    ) -> AVAudioFrameCount {
        let bufferList = UnsafeMutableAudioBufferListPointer(outputData)
        guard let first = bufferList.first, first.mDataByteSize > 0 else { return 0 }
        let channels = max(channelCount, 1)
        if bufferList.count == 1 {
            let sampleCount = Int(first.mDataByteSize) / MemoryLayout<Float>.size
            return AVAudioFrameCount(sampleCount / channels)
        }
        return AVAudioFrameCount(Int(first.mDataByteSize) / MemoryLayout<Float>.size)
    }
}
