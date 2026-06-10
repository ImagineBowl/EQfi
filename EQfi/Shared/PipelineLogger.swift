//
//  PipelineLogger.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation
import os

/// Structured console logging for the AI EQ pipeline.
enum PipelineLogger {
    private static let pipeline = Logger(subsystem: "com.Imaginebowl.EQfi", category: "Pipeline")
    private static let genreProxy = Logger(subsystem: "com.Imaginebowl.EQfi", category: "GenreProxy")
    private static let musicBrainz = Logger(subsystem: "com.Imaginebowl.EQfi", category: "MusicBrainz")
    private static let ollama = Logger(subsystem: "com.Imaginebowl.EQfi", category: "Ollama")

    static func trackDetected(title: String, artist: String, source: String) {
        pipeline.info("Now playing: '\(title, privacy: .public)' by '\(artist, privacy: .public)' [\(source, privacy: .public)]")
    }

    static func genreProxyLookupStarted(title: String, artist: String) {
        genreProxy.info("Looking up genres for '\(title, privacy: .public)' by '\(artist, privacy: .public)'")
    }

    static func genreProxyGenresResolved(_ genres: [String], cached: Bool) {
        let label = cached ? "cache" : "api"
        genreProxy.info("Genre proxy (\(label, privacy: .public)): \(genres.joined(separator: ", "), privacy: .public)")
    }

    static func genreProxyFailed(_ message: String) {
        genreProxy.error("Genre proxy lookup failed: \(message, privacy: .public)")
    }

    static func genreProxyExhaustedTryingFallback() {
        genreProxy.notice("Genre proxy unavailable — trying MusicBrainz fallback")
    }

    static func musicBrainzLookupStarted(title: String, artist: String) {
        musicBrainz.info("Trying MusicBrainz for '\(title, privacy: .public)' by '\(artist, privacy: .public)'")
    }

    static func musicBrainzGenresResolved(_ genres: [String], cached: Bool) {
        let label = cached ? "cache" : "api"
        musicBrainz.info("MusicBrainz genres (\(label, privacy: .public)): \(genres.joined(separator: ", "), privacy: .public)")
    }

    static func musicBrainzFailed(_ message: String) {
        musicBrainz.error("MusicBrainz lookup failed: \(message, privacy: .public)")
    }

    static func ollamaStarted(genre: String, device: String) {
        ollama.info("Generating EQ for genre '\(genre, privacy: .public)' on \(device, privacy: .public)")
    }

    static func ollamaUsingModel(_ model: String) {
        ollama.info("Using Ollama model: \(model, privacy: .public)")
    }

    static func ollamaSucceeded(presetName: String) {
        ollama.info("Ollama EQ ready: \(presetName, privacy: .public)")
    }

    static func ollamaFailed(_ message: String) {
        ollama.error("Ollama generation failed: \(message, privacy: .public)")
    }

    static func fallbackUsed(genres: [String], presetName: String) {
        pipeline.notice("Using fallback preset '\(presetName, privacy: .public)' for genres: \(genres.joined(separator: ", "), privacy: .public)")
    }

    static func eqProfileCacheHit(presetName: String, device: String) {
        pipeline.info("EQ profile cache hit: \(presetName, privacy: .public) on \(device, privacy: .public)")
    }

    static func eqProfileCached(presetName: String, device: String) {
        pipeline.info("Cached EQ profile: \(presetName, privacy: .public) on \(device, privacy: .public)")
    }

    static func eqProfileCachePersistFailed(_ message: String) {
        pipeline.error("EQ profile cache persist failed: \(message, privacy: .public)")
    }

    static func adaptiveFeaturesUpdated(_ features: AudioFeatures) {
        pipeline.debug("Adaptive analysis: \(features.llmSummary, privacy: .public)")
    }
}
