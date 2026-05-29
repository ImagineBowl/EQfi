//
//  Constants.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import AVFoundation
import Foundation

/// Central configuration for URLs, intervals, and prompt templates.
enum Constants {
    enum Spotify {
        static let tokenURL = URL(string: "https://accounts.spotify.com/api/token")
        static let apiBaseURL = URL(string: "https://api.spotify.com/v1")
        static let tokenExpirySeconds: TimeInterval = 3_600
        static let clientIDKey = "spotify_client_id"
        static let clientSecretKey = "spotify_client_secret"

        static var defaultMarket: String {
            Locale.current.region?.identifier ?? "US"
        }
    }

    enum MusicBrainz {
        static let apiBaseURL = URL(string: "https://musicbrainz.org/ws/2")
        static let userAgent = "EQfi/1.0 (com.Imaginebowl.EQfi)"
    }

    enum Ollama {
        static let generateURL = URL(string: "http://localhost:11434/api/generate")
        static let tagsURL = URL(string: "http://localhost:11434/api/tags")
        static let modelName = "llama3.2"
        static let modelFallbackPrefixes = ["llama3.2", "llama3", "llama"]
        static let requestTimeoutSeconds: TimeInterval = 60

        static func promptTemplate(genre: String, device: String) -> String {
            """
            You are an audio engineer. The user is listening to \(genre) on \(device). \
            Return a single JSON object with exactly five numeric fields: \
            sub_bass, bass, midrange, presence, brilliance. \
            Each value must be a float between -12.0 and 12.0. \
            Do not nest objects. Example: \
            {"sub_bass":2.0,"bass":4.0,"midrange":-1.0,"presence":3.0,"brilliance":2.0}
            """
        }
    }

    enum SystemEQ {
        static let tapName = "EQfi-System-Tap"
        static let aggregateDeviceName = "EQfi-Aggregate-Device"
        static let captureQueueLabel = "com.imaginebowl.EQfi.audio-capture"
        static let bandCount = 8
        static let channelCount: UInt32 = 2
        static let defaultSampleRate: Double = 48_000
        static let ringBufferFrames = 16_384
        static let maxRenderFrames: AVAudioFrameCount = 512
        static let statusPollSeconds: TimeInterval = 5
    }

    enum NowPlaying {
        static let pollIntervalSeconds: TimeInterval = 5
    }

    enum ManualEQ {
        static let bandGainMin: Float = -12.0
        static let bandGainMax: Float = 12.0
        static let masterGainMin: Float = -6.0
        static let masterGainMax: Float = 6.0
        static let debounceMilliseconds: TimeInterval = 0.1
    }

    enum AdaptiveEQ {
        static let analysisQueueLabel = "com.imaginebowl.EQfi.audio-analysis"
        static let analysisInterval: TimeInterval = 0.12
        static let fftSize = 4096
        static let sampleQueueCapacity = 32_768
        static let maxBandDeltaDB: Float = 2.5
        static let smoothingFactor: Float = 0.12
        static let featureSmoothingFactor: Float = 0.25
        static let silenceGateDB: Float = -40
        static let logChangeThreshold: Float = 0.08
    }

    enum EQProfileLimits {
        static let gainMin: Float = -12.0
        static let gainMax: Float = 12.0
    }

    enum UserDefaultsKeys {
        static let operatingMode = "eqfi_operating_mode"
        static let genreCache = "eqfi_genre_cache"
        static let eqProfileCache = "eqfi_eq_profile_cache"
        static let customPresets = "eqfi_custom_presets"
    }

    enum Keychain {
        static let serviceName = "com.imaginebowl.EQfi"
    }
}
