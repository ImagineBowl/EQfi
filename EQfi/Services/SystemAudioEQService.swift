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
        await MainActor.run {
            stopEngineOnMainActor()
        }
        try await startEngineWithRecovery()
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

    /// Returns live band gains from the running engine, if available.
    func currentAppliedProfile() async -> EQManualProfile? {
        guard #available(macOS 14.2, *) else { return nil }
        return await MainActor.run {
            typedEngine()?.currentAppliedProfile()
        }
    }

    private func ensureEngineRunning() async throws {
        let needsFullStart = await MainActor.run { () -> Bool in
            guard let engine = typedEngine() else { return true }
            if engine.running() { return false }
            do {
                try engine.reactivate()
                return false
            } catch {
                SystemEQLogger.engineReactivateFailed(error)
                stopEngineOnMainActor()
                return true
            }
        }
        guard needsFullStart else { return }
        try await startEngineWithRecovery()
    }

    private func startEngineWithRecovery() async throws {
        guard #available(macOS 14.2, *) else { throw SystemEQError.unsupportedOSVersion }
        var lastError: Error?
        let attempts = Constants.SystemEQ.engineRecoveryMaxAttempts
        for attempt in 0..<attempts {
            if attempt > 0 {
                SystemEQLogger.engineRestartRetry(attempt: attempt + 1)
                try await Task.sleep(
                    nanoseconds: UInt64(Constants.SystemEQ.engineRecoveryDelaySeconds * 1_000_000_000)
                )
                await MainActor.run {
                    stopEngineOnMainActor()
                }
            }
            do {
                try await MainActor.run {
                    try performFreshEngineStartOnMainActor()
                }
                return
            } catch {
                lastError = error
                SystemEQLogger.engineStartFailed(
                    error,
                    context: "SystemAudioEQEngine.start attempt \(attempt + 1)"
                )
                await MainActor.run {
                    stopEngineOnMainActor()
                }
            }
        }
        let detail = Self.describeError(lastError)
        throw SystemEQError.engineStartFailed(
            "\(detail) Quit other audio apps, wait a few seconds, then toggle EQ again."
        )
    }

    @available(macOS 14.2, *)
    @MainActor
    private func performFreshEngineStartOnMainActor() throws {
        let newEngine = SystemAudioEQEngine()
        try newEngine.start()
        lock.lock()
        engine = newEngine
        isEngineRunning = true
        lock.unlock()
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

    private static func describeError(_ error: Error?) -> String {
        guard let error else { return "unknown" }
        return (error as? LocalizedError)?.errorDescription ?? String(describing: error)
    }
}
