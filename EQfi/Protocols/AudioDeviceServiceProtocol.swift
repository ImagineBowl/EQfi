//
//  AudioDeviceServiceProtocol.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Detects the active system audio output device.
protocol AudioDeviceServiceProtocol: Sendable {
    /// Returns the current output device classification.
    func currentOutputDevice() async throws -> AudioDevice
}
