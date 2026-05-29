//
//  SystemAudioEQService.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Native system-wide EQ service backed by Core Audio Taps.
final class SystemAudioEQService: SystemEQServiceProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var engine: Any?
    private var isEngineRunning = false

    /// Starts the native audio tap and EQ playback engine.
    func startEngine() async throws {
        guard #available(macOS 14.2, *) else { throw SystemEQError.unsupportedOSVersion }
        try await MainActor.run {
            try startEngineOnMainActor()
        }
    }

    /// Stops the audio tap and EQ playback engine.
    func stopEngine() async {
        await MainActor.run {
            stopEngineOnMainActor()
        }
    }

    /// Applies an eight-band profile to the running EQ engine.
    func applyProfile(_ profile: EQManualProfile, adaptiveEnabled: Bool = true) async throws {
        if #available(macOS 14.2, *) {
            try await ensureEngineRunning()
            await MainActor.run {
                typedEngine()?.applyProfile(profile, adaptiveEnabled: adaptiveEnabled)
            }
            return
        }
        throw SystemEQError.unsupportedOSVersion
    }

    /// Returns whether the EQ engine is actively processing audio.
    func isActive() async -> Bool {
        guard #available(macOS 14.2, *) else { return false }
        return await MainActor.run {
            typedEngine()?.running() ?? false
        }
    }

    private func ensureEngineRunning() async throws {
        let active = await isActive()
        if active { return }
        try await startEngine()
    }

    @available(macOS 14.2, *)
    @MainActor
    private func startEngineOnMainActor() throws {
        lock.lock()
        defer { lock.unlock() }
        if isEngineRunning {
            typedEngine()?.stop()
            engine = nil
            isEngineRunning = false
        }
        let newEngine = SystemAudioEQEngine()
        do {
            try newEngine.start()
        } catch {
            newEngine.stop()
            engine = nil
            isEngineRunning = false
            throw SystemEQError.engineStartFailed(error.localizedDescription)
        }
        engine = newEngine
        isEngineRunning = true
    }

    @MainActor
    private func stopEngineOnMainActor() {
        lock.lock()
        defer { lock.unlock() }
        if #available(macOS 14.2, *) {
            typedEngine()?.stop()
        }
        engine = nil
        isEngineRunning = false
    }

    @available(macOS 14.2, *)
    @MainActor
    private func typedEngine() -> SystemAudioEQEngine? {
        engine as? SystemAudioEQEngine
    }
}
