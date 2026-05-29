//
//  AudioDeviceService.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation
import CoreAudio

/// Detects the default audio output device using CoreAudio.
final class AudioDeviceService: AudioDeviceServiceProtocol, @unchecked Sendable {
    /// Returns the current output device classification.
    func currentOutputDevice() async throws -> AudioDevice {
        let deviceID = try defaultOutputDeviceID()
        let name = try deviceName(for: deviceID)
        return classifyDevice(name: name)
    }

    private func defaultOutputDeviceID() throws -> AudioDeviceID {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address, 0, nil, &size, &deviceID
        )
        guard status == noErr else { return 0 }
        return deviceID
    }

    private func deviceName(for deviceID: AudioDeviceID) throws -> String {
        guard let name = CoreAudioPropertyReader.cfString(
            objectID: deviceID,
            selector: kAudioObjectPropertyName
        ) else {
            return ""
        }
        return name as String
    }

    private func classifyDevice(name: String) -> AudioDevice {
        let lowered = name.lowercased()
        if lowered.contains("headphone") || lowered.contains("airpod") || lowered.contains("earphone") {
            return .headphones
        }
        if lowered.contains("speaker") || lowered.contains("macbook") || lowered.contains("imac") {
            return .speakers
        }
        if !name.isEmpty { return .external }
        return .unknown
    }
}
