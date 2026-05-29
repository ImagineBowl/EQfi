//
//  CoreAudioPropertyReader.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import CoreAudio
import Foundation

/// Reads Core Audio object properties without unsafe CFString pointer warnings.
enum CoreAudioPropertyReader {
    /// Reads a CFString property from the given audio object, or `nil` if the read fails.
    static func cfString(
        objectID: AudioObjectID,
        selector: AudioObjectPropertySelector
    ) -> CFString? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var uid = "" as CFString
        var size = UInt32(MemoryLayout<CFString>.size)
        let status = withUnsafeMutablePointer(to: &uid) { uidPointer in
            AudioObjectGetPropertyData(objectID, &address, 0, nil, &size, uidPointer)
        }
        guard status == noErr else { return nil }
        return uid
    }

    /// Returns the default output device ID, if available.
    static func defaultOutputDeviceID() -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        guard status == noErr, deviceID != 0 else { return nil }
        return deviceID
    }

    /// Returns the default output device UID, if available.
    static func defaultOutputDeviceUID() -> String? {
        guard let deviceID = defaultOutputDeviceID() else { return nil }
        return cfString(objectID: deviceID, selector: kAudioDevicePropertyDeviceUID) as String?
    }

    /// Returns the audio process object for this app, if the HAL exposes one.
    static func currentProcessObjectID() -> AudioObjectID? {
        let currentPID = pid_t(ProcessInfo.processInfo.processIdentifier)
        for processID in processObjectList() {
            guard let processPID = pid(for: processID), processPID == currentPID else { continue }
            return processID
        }
        return nil
    }

    /// Process object IDs to exclude from a global tap so EQfi playback is not re-captured.
    static func processObjectIDsExcludedFromGlobalTap() -> [AudioObjectID] {
        guard let processID = currentProcessObjectID() else { return [] }
        return [processID]
    }

    private static func processObjectList() -> [AudioObjectID] {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyProcessObjectList,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize
        ) == noErr, dataSize > 0 else {
            return []
        }

        let count = Int(dataSize) / MemoryLayout<AudioObjectID>.size
        var processes = [AudioObjectID](repeating: 0, count: count)
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize,
            &processes
        ) == noErr else {
            return []
        }
        return processes
    }

    private static func pid(for processObjectID: AudioObjectID) -> pid_t? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioProcessPropertyPID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var processPID = pid_t(0)
        var size = UInt32(MemoryLayout<pid_t>.size)
        let status = AudioObjectGetPropertyData(
            processObjectID,
            &address,
            0,
            nil,
            &size,
            &processPID
        )
        guard status == noErr, processPID > 0 else { return nil }
        return processPID
    }
}
