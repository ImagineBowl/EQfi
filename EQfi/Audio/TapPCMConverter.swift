//
//  TapPCMConverter.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import AVFoundation
import CoreAudio
import Foundation

/// Converts tap AudioBufferList payloads into interleaved stereo float samples.
final class TapPCMConverter {
    let outputFormat: AVAudioFormat
    private let tapFormat: AVAudioFormat
    private let converter: AVAudioConverter?
    private var convertedBuffer: AVAudioPCMBuffer?
    private var scratchSamples: [Float] = []
    private var sampleTap: ((UnsafePointer<Float>, Int) -> Void)?

    init(tapFormat: AVAudioFormat, sampleTap: ((UnsafePointer<Float>, Int) -> Void)? = nil) throws {
        self.sampleTap = sampleTap
        self.tapFormat = tapFormat
        let sampleRate = tapFormat.sampleRate > 0 ? tapFormat.sampleRate : Constants.SystemEQ.defaultSampleRate
        guard let outputFormat = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: Constants.SystemEQ.channelCount
        ) else {
            throw SystemEQError.engineStartFailed("Unable to create PCM converter output format.")
        }
        self.outputFormat = outputFormat
        if tapFormat.isEqual(outputFormat) {
            converter = nil
        } else {
            guard let converter = AVAudioConverter(from: tapFormat, to: outputFormat) else {
                throw SystemEQError.engineStartFailed("Unable to create PCM converter.")
            }
            self.converter = converter
        }
    }

    /// Writes converted tap input directly into the ring buffer.
    @discardableResult
    func write(to ringBuffer: AudioRingBuffer, from inputData: UnsafePointer<AudioBufferList>) -> Int {
        let frameCount = frameCount(for: inputData)
        guard frameCount > 0 else { return 0 }

        if let inputBuffer = makeInputBuffer(from: inputData, frameCount: frameCount) {
            if converter == nil, let samples = readInterleavedFloat(from: inputBuffer) {
                return write(samples: samples, to: ringBuffer)
            }
            if let converted = convertWithEngine(inputBuffer: inputBuffer, frameCount: frameCount) {
                return write(samples: converted, to: ringBuffer)
            }
        }

        guard let samples = readFloatDirectly(from: inputData, frameCount: frameCount) else { return 0 }
        return write(samples: samples, to: ringBuffer)
    }

    private func write(samples: [Float], to ringBuffer: AudioRingBuffer) -> Int {
        guard !samples.isEmpty else { return 0 }
        samples.withUnsafeBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            sampleTap?(baseAddress, buffer.count)
            ringBuffer.write(baseAddress, count: buffer.count)
        }
        return samples.count
    }

    private func convertWithEngine(
        inputBuffer: AVAudioPCMBuffer,
        frameCount: AVAudioFrameCount
    ) -> [Float]? {
        guard let converter else { return nil }
        guard let outputBuffer = makeOutputBuffer(frameCount: frameCount) else { return nil }

        var consumed = false
        var error: NSError?
        let status = converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            if consumed {
                outStatus.pointee = .noDataNow
                return nil
            }
            consumed = true
            outStatus.pointee = .haveData
            return inputBuffer
        }
        guard status != .error, error == nil else { return nil }
        return readInterleavedFloat(from: outputBuffer)
    }

    private func frameCount(for inputData: UnsafePointer<AudioBufferList>) -> AVAudioFrameCount {
        let bufferList = UnsafeMutableAudioBufferListPointer(
            UnsafeMutablePointer(mutating: inputData)
        )
        guard !bufferList.isEmpty else { return 0 }

        if tapFormat.isInterleaved, let first = bufferList.first {
            let bytesPerFrame = max(Int(tapFormat.streamDescription.pointee.mBytesPerFrame), 1)
            return AVAudioFrameCount(Int(first.mDataByteSize) / bytesPerFrame)
        }

        let bytesPerFrame = max(Int(tapFormat.streamDescription.pointee.mBytesPerFrame), MemoryLayout<Float>.size)
        let maxBytes = bufferList.map(\.mDataByteSize).max() ?? 0
        return AVAudioFrameCount(Int(maxBytes) / bytesPerFrame)
    }

    private func makeInputBuffer(
        from inputData: UnsafePointer<AudioBufferList>,
        frameCount: AVAudioFrameCount
    ) -> AVAudioPCMBuffer? {
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: tapFormat,
            bufferListNoCopy: inputData,
            deallocator: nil
        ) else {
            return nil
        }
        buffer.frameLength = frameCount
        return buffer
    }

    private func makeOutputBuffer(frameCount: AVAudioFrameCount) -> AVAudioPCMBuffer? {
        if let convertedBuffer, convertedBuffer.frameCapacity >= frameCount {
            convertedBuffer.frameLength = frameCount
            return convertedBuffer
        }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: frameCount) else {
            return nil
        }
        buffer.frameLength = frameCount
        convertedBuffer = buffer
        return buffer
    }

    private func readInterleavedFloat(from buffer: AVAudioPCMBuffer) -> [Float]? {
        guard let channels = buffer.floatChannelData else { return nil }
        let frameCount = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        guard frameCount > 0, channelCount > 0 else { return nil }

        let sampleCount = frameCount * channelCount
        scratchSamples.removeAll(keepingCapacity: true)
        scratchSamples.reserveCapacity(sampleCount)

        if buffer.format.isInterleaved {
            scratchSamples.append(contentsOf: UnsafeBufferPointer(start: channels[0], count: sampleCount))
            return scratchSamples
        }

        for frame in 0..<frameCount {
            for channel in 0..<channelCount {
                scratchSamples.append(channels[channel][frame])
            }
        }
        return scratchSamples
    }

    private func readFloatDirectly(
        from inputData: UnsafePointer<AudioBufferList>,
        frameCount: AVAudioFrameCount
    ) -> [Float]? {
        guard tapFormat.commonFormat == .pcmFormatFloat32 else { return nil }
        let bufferList = UnsafeMutableAudioBufferListPointer(
            UnsafeMutablePointer(mutating: inputData)
        )
        guard !bufferList.isEmpty else { return nil }

        let frames = Int(frameCount)
        let channels = Int(tapFormat.channelCount)
        let sampleCount = frames * channels
        scratchSamples.removeAll(keepingCapacity: true)
        scratchSamples.reserveCapacity(sampleCount)

        if tapFormat.isInterleaved, let data = bufferList[0].mData {
            data.withMemoryRebound(to: Float.self, capacity: sampleCount) { pointer in
                scratchSamples.append(contentsOf: UnsafeBufferPointer(start: pointer, count: sampleCount))
            }
            return scratchSamples
        }

        for frame in 0..<frames {
            for channel in 0..<min(channels, bufferList.count) {
                guard let data = bufferList[channel].mData else {
                    scratchSamples.append(0)
                    continue
                }
                let pointer = data.assumingMemoryBound(to: Float.self)
                scratchSamples.append(pointer[frame])
            }
        }
        return scratchSamples
    }
}
