//
//  SystemAudioTapManager.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import AVFoundation
import CoreAudio
import Foundation

/// Creates and manages a Core Audio process tap and private aggregate device.
@available(macOS 14.2, *)
final class SystemAudioTapManager {
    private(set) var tapID: AudioObjectID = kAudioObjectUnknown
    private(set) var aggregateDeviceID: AudioObjectID = kAudioObjectUnknown
    private(set) var streamFormat: AVAudioFormat?
    private var tapDescription: CATapDescription?

    /// Builds a tap on the default output device and wires it into a capture-only aggregate.
    func setup() throws {
        guard let deviceUID = CoreAudioPropertyReader.defaultOutputDeviceUID() else {
            let error = SystemEQError.engineStartFailed("Unable to resolve default output device.")
            SystemEQLogger.tapStepFailed("resolve default output device", error: error)
            throw error
        }
        SystemEQLogger.engineStarting(outputDeviceUID: deviceUID)
        tapID = try createProcessTap(deviceUID: deviceUID)
        aggregateDeviceID = try createAggregateDevice()
        streamFormat = try readTapFormat()
    }

    /// Destroys tap and aggregate device resources.
    func teardown() {
        if aggregateDeviceID != kAudioObjectUnknown {
            AudioHardwareDestroyAggregateDevice(aggregateDeviceID)
            aggregateDeviceID = kAudioObjectUnknown
        }
        if tapID != kAudioObjectUnknown {
            AudioHardwareDestroyProcessTap(tapID)
            tapID = kAudioObjectUnknown
        }
        tapDescription = nil
        streamFormat = nil
    }

    private func createProcessTap(deviceUID: String) throws -> AudioObjectID {
        let excludedProcesses = CoreAudioPropertyReader.processObjectIDsExcludedFromGlobalTap()
        let description = CATapDescription(
            excludingProcesses: excludedProcesses,
            deviceUID: deviceUID,
            stream: 0
        )
        description.name = Constants.SystemEQ.tapName
        description.isPrivate = true
        description.muteBehavior = .muted
        tapDescription = description

        var newTapID = AudioObjectID(kAudioObjectUnknown)
        let status = AudioHardwareCreateProcessTap(description, &newTapID)
        guard status == noErr else {
            SystemEQLogger.tapStepFailed(
                "create process tap",
                error: SystemEQError.tapCreationFailed(status: status)
            )
            throw SystemEQError.tapCreationFailed(status: status)
        }
        return newTapID
    }

    private func createAggregateDevice() throws -> AudioObjectID {
        guard let tapUUID = tapDescription?.uuid.uuidString else {
            throw SystemEQError.aggregateDeviceFailed(status: -1)
        }

        let tapEntry: [String: Any] = [
            kAudioSubTapUIDKey as String: tapUUID,
            kAudioSubTapDriftCompensationKey as String: true
        ]
        let description: [String: Any] = [
            kAudioAggregateDeviceNameKey as String: Constants.SystemEQ.aggregateDeviceName,
            kAudioAggregateDeviceUIDKey as String: UUID().uuidString,
            kAudioAggregateDeviceIsPrivateKey as String: true,
            kAudioAggregateDeviceTapListKey as String: [tapEntry],
            kAudioAggregateDeviceTapAutoStartKey as String: false
        ]

        var deviceID = AudioObjectID(kAudioObjectUnknown)
        let status = AudioHardwareCreateAggregateDevice(description as CFDictionary, &deviceID)
        guard status == noErr else {
            SystemEQLogger.tapStepFailed(
                "create aggregate device",
                error: SystemEQError.aggregateDeviceFailed(status: status)
            )
            throw SystemEQError.aggregateDeviceFailed(status: status)
        }
        return deviceID
    }

    private func readTapFormat() throws -> AVAudioFormat {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioTapPropertyFormat,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var description = AudioStreamBasicDescription()
        var size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        let status = AudioObjectGetPropertyData(tapID, &address, 0, nil, &size, &description)
        guard status == noErr else {
            SystemEQLogger.tapFormatRejected(status: status, streamDescription: description)
            throw SystemEQError.engineStartFailed("Unsupported tap audio format.")
        }
        var mutableDescription = description
        let usedDirectInitializer = AVAudioFormat(streamDescription: &mutableDescription) != nil
        guard let format = TapAudioFormatBuilder.format(from: description) else {
            SystemEQLogger.tapFormatRejected(status: status, streamDescription: description)
            throw SystemEQError.engineStartFailed("Unsupported tap audio format.")
        }
        if !usedDirectInitializer {
            SystemEQLogger.tapFormatResolvedFromASBD(format: format)
        }
        return format
    }
}
