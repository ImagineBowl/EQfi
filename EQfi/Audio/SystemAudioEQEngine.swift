//
//  SystemAudioEQEngine.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import AVFoundation
import CoreAudio
import Foundation

/// Captures system audio via Core Audio Tap and plays EQ-processed audio through AVAudioEngine.
@available(macOS 14.2, *)
final class SystemAudioEQEngine: @unchecked Sendable {
    private var tapManager = SystemAudioTapManager()
    private var audioEngine: AVAudioEngine?
    private var eqUnit: AVAudioUnitEQ?
    private var sourceNode: AVAudioSourceNode?
    private var ringBuffer: AudioRingBuffer?
    private var pcmConverter: TapPCMConverter?
    private var ioProcID: AudioDeviceIOProcID?
    private var processingFormat: AVAudioFormat?
    private var channelCount = Int(Constants.SystemEQ.channelCount)
    private var isRunning = false
    private var scratchSamples: [Float] = []
    private var adaptiveController: AdaptiveEQController?
    private let captureQueue = DispatchQueue(label: Constants.SystemEQ.captureQueueLabel)

    /// Starts tap capture and EQ playback.
    func start() throws {
        guard !isRunning else { return }
        stop()
        tapManager = SystemAudioTapManager()
        let engine = AVAudioEngine()
        let eq = AVAudioUnitEQ(numberOfBands: Constants.SystemEQ.bandCount)
        audioEngine = engine
        eqUnit = eq
        do {
            try tapManager.setup()
            let tapFormat = try requireTapFormat()
            let sampleRate = tapFormat.sampleRate > 0 ? tapFormat.sampleRate : Constants.SystemEQ.defaultSampleRate
            let adaptive = AdaptiveEQController(sampleRate: sampleRate)
            adaptiveController = adaptive
            pcmConverter = try TapPCMConverter(tapFormat: tapFormat) { samples, count in
                adaptive.enqueueSamples(samples, count: count)
            }
            let engineFormat = pcmConverter?.outputFormat ?? tapFormat
            processingFormat = engineFormat
            channelCount = Int(engineFormat.channelCount)
            ringBuffer = AudioRingBuffer(
                frameCapacity: Constants.SystemEQ.ringBufferFrames,
                channelCount: channelCount
            )
            scratchSamples = Array(repeating: 0, count: Int(Constants.SystemEQ.maxRenderFrames) * channelCount)
            try configureEngine(engine: engine, eqUnit: eq, format: engineFormat)
            adaptive.attach(eqUnit: eq, mixer: engine.mainMixerNode, channelCount: channelCount)
            isRunning = true
            try engine.start()
            try startCaptureLoop()
        } catch {
            stop()
            throw error
        }
    }

    /// Stops capture and playback and releases audio resources.
    func stop() {
        isRunning = false
        adaptiveController?.detach()
        adaptiveController = nil
        stopCaptureLoop()
        stopAudioEngine()
        tapManager.teardown()
        pcmConverter = nil
        sourceNode = nil
        ringBuffer = nil
        processingFormat = nil
        eqUnit = nil
        audioEngine = nil
        scratchSamples.removeAll(keepingCapacity: false)
    }

    /// Returns whether the engine is actively running.
    func running() -> Bool {
        isRunning && (audioEngine?.isRunning ?? false)
    }

    /// Applies a new EQ profile to the running engine.
    func applyProfile(_ profile: EQManualProfile, adaptiveEnabled: Bool = true) {
        adaptiveController?.setEnabled(adaptiveEnabled)
        adaptiveController?.updateBaseProfile(profile)
        guard !adaptiveEnabled, let eqUnit, let audioEngine else { return }
        EQBandConfigurator.apply(
            profile: profile,
            to: eqUnit,
            mixer: audioEngine.mainMixerNode
        )
    }

    private func requireTapFormat() throws -> AVAudioFormat {
        guard let format = tapManager.streamFormat else {
            throw SystemEQError.engineStartFailed("Missing tap audio format.")
        }
        return format
    }

    private func configureEngine(
        engine: AVAudioEngine,
        eqUnit: AVAudioUnitEQ,
        format: AVAudioFormat
    ) throws {
        let sourceNode = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, inputData in
            guard let self else { return noErr }
            return self.renderFromRingBuffer(frameCount: frameCount, inputData: inputData)
        }
        self.sourceNode = sourceNode
        engine.attach(sourceNode)
        engine.attach(eqUnit)
        engine.connect(sourceNode, to: eqUnit, format: format)
        engine.connect(eqUnit, to: engine.mainMixerNode, format: format)
        engine.connect(engine.mainMixerNode, to: engine.outputNode, format: nil)
    }

    private func startCaptureLoop() throws {
        var procID: AudioDeviceIOProcID?
        let deviceID = tapManager.aggregateDeviceID
        let status = AudioDeviceCreateIOProcIDWithBlock(&procID, deviceID, captureQueue) {
            [weak self] _, inputData, _, _, _ in
            guard let self else { return }
            self.writeInputToRingBuffer(inputData)
        }
        guard status == noErr, let procID else {
            throw SystemEQError.engineStartFailed("Unable to create IOProc.")
        }
        ioProcID = procID
        let startStatus = AudioDeviceStart(deviceID, procID)
        guard startStatus == noErr else {
            throw SystemEQError.engineStartFailed("Unable to start system audio tap.")
        }
    }

    private func stopCaptureLoop() {
        guard let ioProcID, tapManager.aggregateDeviceID != kAudioObjectUnknown else {
            self.ioProcID = nil
            return
        }
        let deviceID = tapManager.aggregateDeviceID
        let procID = ioProcID
        self.ioProcID = nil
        AudioDeviceStop(deviceID, procID)
        captureQueue.sync { }
        AudioDeviceDestroyIOProcID(deviceID, procID)
    }

    private func stopAudioEngine() {
        guard let engine = audioEngine, engine.isRunning else { return }
        engine.stop()
    }

    private func writeInputToRingBuffer(_ inputData: UnsafePointer<AudioBufferList>) {
        guard isRunning, let ringBuffer, let pcmConverter else { return }
        pcmConverter.write(to: ringBuffer, from: inputData)
    }

    private func renderFromRingBuffer(
        frameCount: AVAudioFrameCount,
        inputData: UnsafeMutablePointer<AudioBufferList>?
    ) -> OSStatus {
        guard let inputData else { return noErr }
        let bufferList = UnsafeMutableAudioBufferListPointer(inputData)
        let samplesNeeded = Int(frameCount) * channelCount

        guard isRunning, let ringBuffer, scratchSamples.count >= samplesNeeded else {
            zeroFill(bufferList)
            return noErr
        }

        scratchSamples.withUnsafeMutableBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else { return }
            ringBuffer.read(into: baseAddress, count: samplesNeeded)
        }

        guard let format = processingFormat else {
            zeroFill(bufferList)
            return noErr
        }

        if format.isInterleaved, bufferList.count == 1, let data = bufferList[0].mData {
            let byteCount = min(
                Int(bufferList[0].mDataByteSize),
                samplesNeeded * MemoryLayout<Float>.size
            )
            data.copyMemory(from: scratchSamples, byteCount: byteCount)
            return noErr
        }

        let frames = Int(frameCount)
        for channel in 0..<min(channelCount, bufferList.count) {
            guard let data = bufferList[channel].mData else { continue }
            data.withMemoryRebound(to: Float.self, capacity: frames) { destination in
                for frame in 0..<frames {
                    let sampleIndex = frame * channelCount + channel
                    destination[frame] = scratchSamples[sampleIndex]
                }
            }
        }
        return noErr
    }

    private func zeroFill(_ bufferList: UnsafeMutableAudioBufferListPointer) {
        for buffer in bufferList {
            guard let data = buffer.mData else { continue }
            memset(data, 0, Int(buffer.mDataByteSize))
        }
    }
}
