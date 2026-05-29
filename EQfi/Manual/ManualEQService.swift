//
//  ManualEQService.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Applies manual eight-band EQ changes with debouncing.
final class ManualEQService: ManualEQServiceProtocol, @unchecked Sendable {
    private let systemEQ: SystemEQServiceProtocol
    private let debouncer: Debouncer
    private let lock = NSLock()
    private var lastProfile: EQManualProfile?

    init(
        systemEQ: SystemEQServiceProtocol,
        debounceDelay: TimeInterval = Constants.ManualEQ.debounceMilliseconds
    ) {
        self.systemEQ = systemEQ
        self.debouncer = Debouncer(delay: debounceDelay)
    }

    /// Applies bands immediately (presets, reset, mode switch).
    func applyBands(_ bands: [EQBand], masterGain: Float) async throws {
        debouncer.cancel()
        try await sendProfile(bands: bands, masterGain: masterGain)
    }

    /// Applies bands after a debounce delay for live slider movement.
    func applyBandsDebounced(_ bands: [EQBand], masterGain: Float) {
        debouncer.call { [weak self] in
            Task { await self?.sendProfileSilently(bands: bands, masterGain: masterGain) }
        }
    }

    /// Returns the last profile successfully applied.
    func currentProfile() -> EQManualProfile? {
        lock.lock()
        defer { lock.unlock() }
        return lastProfile
    }

    private func sendProfile(bands: [EQBand], masterGain: Float) async throws {
        let profile = EQManualProfile(bands: bands, masterGain: masterGain, presetName: nil)
        cacheProfile(profile)
        try await systemEQ.applyProfile(profile, adaptiveEnabled: false)
    }

    private func sendProfileSilently(bands: [EQBand], masterGain: Float) async {
        do {
            try await sendProfile(bands: bands, masterGain: masterGain)
        } catch {
            return
        }
    }

    private func cacheProfile(_ profile: EQManualProfile) {
        lock.lock()
        lastProfile = profile
        lock.unlock()
    }
}
