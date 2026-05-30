//
//  EQOrchestrator.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Coordinates the AI pipeline from track detection through native EQ application.
final class EQOrchestrator: EQOrchestratorProtocol, @unchecked Sendable {
    private let nowPlaying: NowPlayingServiceProtocol
    private let systemEQ: SystemEQServiceProtocol
    private let pipeline: EQPipelineRunner
    private var pipelineTask: Task<Void, Never>?
    private let lock = NSLock()
    private var state: EQState = .idle
    private var isEnabled = true

    var onStateChange: (@Sendable (EQState) -> Void)?
    var onProfileApplied: (@Sendable (EQPipelineResult) -> Void)?

    var currentState: EQState {
        lock.lock()
        defer { lock.unlock() }
        return state
    }

    init(
        nowPlaying: NowPlayingServiceProtocol,
        spotify: SpotifyServiceProtocol,
        genreFallback: GenreLookupFallbackProtocol,
        profileCache: EQProfileCacheProtocol,
        ollama: OllamaServiceProtocol,
        systemEQ: SystemEQServiceProtocol,
        audioDevice: AudioDeviceServiceProtocol
    ) {
        self.nowPlaying = nowPlaying
        self.systemEQ = systemEQ
        self.pipeline = EQPipelineRunner(
            spotify: spotify,
            genreFallback: genreFallback,
            profileCache: profileCache,
            ollama: ollama,
            audioDevice: audioDevice
        )
    }

    /// Marks the orchestrator as ready to process tracks.
    func startListening() {
        updateState(.idle)
    }

    /// Cancels in-flight pipeline work.
    func stopListening() {
        pipelineTask?.cancel()
        pipelineTask = nil
        updateState(.idle)
    }

    /// Immediately re-runs the pipeline for the current track.
    func refreshCurrentTrack() async {
        await retryCurrentTrack()
    }

    /// Processes a detected track through the full AI pipeline.
    func processTrack(_ track: TrackInfo) async {
        pipelineTask?.cancel()
        await runPipeline(for: track, allowWhenDisabled: false)
    }

    /// Re-runs the pipeline even when EQ is disabled so the UI can refresh.
    func retryCurrentTrack() async {
        pipelineTask?.cancel()
        let track: TrackInfo?
        do {
            track = try await nowPlaying.currentTrack()
        } catch {
            return
        }
        guard let track else { return }
        await runPipeline(for: track, allowWhenDisabled: true)
    }

    /// Enables or disables automatic EQ application.
    func setEnabled(_ enabled: Bool) {
        lock.lock()
        isEnabled = enabled
        lock.unlock()
    }

    private func runPipeline(for track: TrackInfo, allowWhenDisabled: Bool) async {
        guard allowWhenDisabled || isPipelineEnabled else { return }
        updateState(.detecting)
        let result = await pipeline.run(for: track)
        guard !Task.isCancelled else { return }
        guard allowWhenDisabled || isPipelineEnabled else { return }
        updateState(.applying)
        await applyProfile(result, applyToEngine: isPipelineEnabled)
    }

    private func applyProfile(_ result: EQPipelineResult, applyToEngine: Bool) async {
        if applyToEngine {
            let manual = EQProfileBridge.toEightBand(result.profile)
            do {
                try await systemEQ.applyProfile(manual, adaptiveEnabled: true)
                updateState(.idle)
                onProfileApplied?(result)
            } catch {
                updateState(.error(message: error.localizedDescription))
            }
            return
        }
        updateState(.idle)
        onProfileApplied?(result)
    }

    private var isPipelineEnabled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return isEnabled
    }

    private func updateState(_ newState: EQState) {
        lock.lock()
        state = newState
        lock.unlock()
        onStateChange?(newState)
    }
}
