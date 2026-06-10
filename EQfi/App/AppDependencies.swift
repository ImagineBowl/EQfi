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

    /// Creates and connects all application dependencies.
    static func make() -> AppDependencies {
        let genreCache = GenreCache()
        let profileCache = EQProfileCache()
        let genreProxy = GenreProxyService(cache: genreCache)
        let musicBrainz = MusicBrainzService(cache: genreCache)
        let nowPlaying = NowPlayingService()
        let ollamaModelResolver = OllamaModelResolver()
        let ollama = OllamaService(modelResolver: ollamaModelResolver)
        let systemEQ = SystemAudioEQService()
        let audioDevice = AudioDeviceService()
        let orchestrator = EQOrchestrator(
            nowPlaying: nowPlaying,
            primaryGenreLookup: genreProxy,
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
        let updateChecker = UpdateCheckerService()
        let viewModel = EQViewModel(
            nowPlaying: nowPlaying,
            orchestrator: orchestrator,
            systemEQ: systemEQ,
            modePreference: modePreference,
            manualViewModel: manualVM,
            systemEQMonitor: systemEQMonitor,
            ollamaMonitor: ollamaMonitor,
            updateChecker: updateChecker
        )
        return AppDependencies(viewModel: viewModel)
    }
}
