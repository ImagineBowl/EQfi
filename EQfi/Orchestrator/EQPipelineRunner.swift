//
//  EQPipelineRunner.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Executes a single AI pipeline pass for one track.
struct EQPipelineRunner {
    private let spotify: SpotifyServiceProtocol
    private let genreFallback: GenreLookupFallbackProtocol
    private let profileCache: EQProfileCacheProtocol
    private let ollama: OllamaServiceProtocol
    private let audioDevice: AudioDeviceServiceProtocol

    init(
        spotify: SpotifyServiceProtocol,
        genreFallback: GenreLookupFallbackProtocol,
        profileCache: EQProfileCacheProtocol,
        ollama: OllamaServiceProtocol,
        audioDevice: AudioDeviceServiceProtocol
    ) {
        self.spotify = spotify
        self.genreFallback = genreFallback
        self.profileCache = profileCache
        self.ollama = ollama
        self.audioDevice = audioDevice
    }

    /// Resolves genre and generates an EQ profile for the track.
    func run(for track: TrackInfo) async -> EQPipelineResult {
        PipelineLogger.trackDetected(title: track.title, artist: track.artist, source: track.source.rawValue)
        let genres = await resolveGenres(for: track)
        let profileResult = await generateProfile(for: track, genres: genres)
        return EQPipelineResult(
            profile: profileResult.profile,
            genres: genres,
            usedFallback: profileResult.usedFallback,
            profileFromCache: profileResult.fromCache
        )
    }

    private func resolveGenres(for track: TrackInfo) async -> [String] {
        if track.isPodcast {
            PipelineLogger.spotifyGenresResolved(["podcast"], cached: false)
            return ["podcast"]
        }

        PipelineLogger.spotifyLookupStarted(title: track.title, artist: track.artist)
        do {
            return try await spotify.fetchGenre(for: track)
        } catch {
            PipelineLogger.spotifyFailed(error.localizedDescription)
        }

        PipelineLogger.spotifyExhaustedTryingFallback()
        PipelineLogger.musicBrainzLookupStarted(title: track.title, artist: track.artist)
        do {
            return try await genreFallback.fetchGenre(for: track)
        } catch {
            PipelineLogger.musicBrainzFailed(error.localizedDescription)
            return ["unknown"]
        }
    }

    private func generateProfile(
        for track: TrackInfo,
        genres: [String]
    ) async -> (profile: EQProfile, usedFallback: Bool, fromCache: Bool) {
        let outputDevice = await resolveDevice()
        let cacheKey = track.eqProfileCacheKey(device: outputDevice)

        if let cached = profileCache.profile(forKey: cacheKey) {
            PipelineLogger.eqProfileCacheHit(
                presetName: cached.profile.presetName,
                device: outputDevice.displayName
            )
            return (cached.profile, cached.usedFallback, true)
        }

        let genreLabel = genres.filter { $0 != "unknown" }.joined(separator: ", ")
        let ollamaGenre = genreLabel.isEmpty ? "unknown" : genreLabel
        let generated: (profile: EQProfile, usedFallback: Bool)
        do {
            PipelineLogger.ollamaStarted(genre: ollamaGenre, device: outputDevice.displayName)
            let profile = try await ollama.generateEQProfile(genre: ollamaGenre, device: outputDevice)
            PipelineLogger.ollamaSucceeded(presetName: profile.presetName)
            generated = (profile, false)
        } catch {
            PipelineLogger.ollamaFailed(error.localizedDescription)
            let profile = FallbackEQProvider.profile(for: genres)
            PipelineLogger.fallbackUsed(genres: genres, presetName: profile.presetName)
            generated = (profile, true)
        }

        profileCache.store(
            CachedEQProfile(profile: generated.profile, usedFallback: generated.usedFallback),
            forKey: cacheKey
        )
        PipelineLogger.eqProfileCached(presetName: generated.profile.presetName, device: outputDevice.displayName)
        return (generated.profile, generated.usedFallback, false)
    }

    private func resolveDevice() async -> AudioDevice {
        do {
            return try await audioDevice.currentOutputDevice()
        } catch {
            return .unknown
        }
    }
}
