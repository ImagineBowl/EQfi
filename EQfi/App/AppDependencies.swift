//
//  AppDependencies.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Composition root that wires concrete services and ViewModels.
@MainActor
struct AppDependencies {
    let viewModel: EQViewModel
    let keychain: KeychainServiceProtocol

    /// Creates and connects all application dependencies.
    static func make() -> AppDependencies {
        let keychain = KeychainService()
        let genreCache = GenreCache()
        let profileCache = EQProfileCache()
        let tokenManager = SpotifyTokenManager(keychain: keychain)
        let spotify = SpotifyService(tokenManager: tokenManager, cache: genreCache)
        let musicBrainz = MusicBrainzService(cache: genreCache)
        let nowPlaying = NowPlayingService()
        let ollamaModelResolver = OllamaModelResolver()
        let ollama = OllamaService(modelResolver: ollamaModelResolver)
        let systemEQ = SystemAudioEQService()
        let audioDevice = AudioDeviceService()
        let orchestrator = EQOrchestrator(
            nowPlaying: nowPlaying,
            spotify: spotify,
            genreFallback: musicBrainz,
            profileCache: profileCache,
            ollama: ollama,
            systemEQ: systemEQ,
            audioDevice: audioDevice
        )
        let manualEQ = ManualEQService(systemEQ: systemEQ)
        let presetStore = CustomPresetStore()
        let manualVM = ManualEQViewModel(manualEQ: manualEQ, presetStore: presetStore)
        let systemEQMonitor = SystemEQStatusMonitor(systemEQ: systemEQ)
        let ollamaMonitor = OllamaStatusMonitor(modelResolver: ollamaModelResolver)
        let modePreference = ModePreferenceService()
        let viewModel = EQViewModel(
            nowPlaying: nowPlaying,
            orchestrator: orchestrator,
            systemEQ: systemEQ,
            modePreference: modePreference,
            keychain: keychain,
            manualViewModel: manualVM,
            systemEQMonitor: systemEQMonitor,
            ollamaMonitor: ollamaMonitor
        )
        return AppDependencies(viewModel: viewModel, keychain: keychain)
    }
}
