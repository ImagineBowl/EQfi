//
//  NowPlayingService.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Polls the system for now-playing track changes via AppleScript.
final class NowPlayingService: NowPlayingServiceProtocol, @unchecked Sendable {
    private let scriptRunner: NowPlayingScriptRunner
    private var pollingTask: Task<Void, Never>?
    private var lastTrackKey: String?
    private let lock = NSLock()

    var onTrackChange: (@Sendable (TrackInfo) -> Void)?

    init(scriptRunner: NowPlayingScriptRunner = NowPlayingScriptRunner()) {
        self.scriptRunner = scriptRunner
    }

    /// Returns the currently playing track, if any.
    func currentTrack() async throws -> TrackInfo? {
        try scriptRunner.detectTrack()
    }

    /// Starts polling for track changes at the given interval.
    func startPolling(interval: TimeInterval) {
        stopPolling()
        pollingTask = Task { [weak self] in
            await self?.pollLoop(interval: interval)
        }
    }

    /// Stops active track polling.
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    private func pollLoop(interval: TimeInterval) async {
        while !Task.isCancelled {
            await pollOnce()
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }
    }

    private func pollOnce() async {
        let track: TrackInfo?
        do {
            track = try scriptRunner.detectTrack()
        } catch {
            return
        }
        guard let track else { return }
        emitIfChanged(track)
    }

    private func emitIfChanged(_ track: TrackInfo) {
        let key = track.cacheKey
        lock.lock()
        let changed = lastTrackKey != key
        if changed { lastTrackKey = key }
        let callback = onTrackChange
        lock.unlock()
        if changed { callback?(track) }
    }
}
