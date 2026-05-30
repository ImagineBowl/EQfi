//
//  EQViewModel.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Main menubar ViewModel coordinating AI and manual EQ modes.
@MainActor
@Observable
final class EQViewModel: EQViewModelProtocol {
    var currentTrack: TrackInfo?
    var detectedGenres: [String] = []
    var eqSourceLabel = ""
    var currentProfile: EQProfile?
    var manualProfile: EQManualProfile?
    var pipelineState: EQState = .idle
    var mode: EQfiMode = .ai
    var isEQEnabled = false
    var ollamaStatus: ServiceConnectionStatus = .disconnected
    var ollamaAvailability: OllamaAvailability = .notInstalled
    var systemEQStatus: ServiceConnectionStatus = .disconnected
    var errorMessage: String?
    var showOnboarding = false
    var needsSystemAudioPermission = false

    let manualViewModel: ManualEQViewModel

    private let nowPlaying: NowPlayingServiceProtocol
    private let orchestrator: EQOrchestrator
    private let systemEQ: SystemEQServiceProtocol
    private let modePreference: ModePreferenceServiceProtocol
    private let keychain: KeychainServiceProtocol
    private let systemEQMonitor: SystemEQStatusMonitor
    private let ollamaMonitor: OllamaStatusMonitor
    private var isEngineTransitioning = false

    init(
        nowPlaying: NowPlayingServiceProtocol,
        orchestrator: EQOrchestrator,
        systemEQ: SystemEQServiceProtocol,
        modePreference: ModePreferenceServiceProtocol,
        keychain: KeychainServiceProtocol,
        manualViewModel: ManualEQViewModel,
        systemEQMonitor: SystemEQStatusMonitor,
        ollamaMonitor: OllamaStatusMonitor
    ) {
        self.nowPlaying = nowPlaying
        self.orchestrator = orchestrator
        self.systemEQ = systemEQ
        self.modePreference = modePreference
        self.keychain = keychain
        self.manualViewModel = manualViewModel
        self.systemEQMonitor = systemEQMonitor
        self.ollamaMonitor = ollamaMonitor
        self.mode = modePreference.loadMode()
        bindOrchestratorCallbacks()
        bindMonitorCallbacks()
    }

    /// Toggles EQ application on or off.
    func toggleEQEnabled() {
        guard !isEngineTransitioning else { return }
        isEQEnabled.toggle()
        Task { await handleEQToggle() }
    }

    /// Switches between AI and manual operating modes.
    func setMode(_ newMode: EQfiMode) {
        guard newMode != mode else { return }
        let previousMode = mode
        mode = newMode
        modePreference.saveMode(newMode)
        handleModeTransition(from: previousMode, to: newMode)
    }

    /// Starts all background monitoring and pipeline tasks.
    func start() {
        showOnboarding = !keychain.hasSpotifyCredentials()
        orchestrator.setEnabled(isEQEnabled)
        orchestrator.startListening()
        bindNowPlayingCallback()
        nowPlaying.startPolling(interval: Constants.NowPlaying.pollIntervalSeconds)
        systemEQMonitor.startMonitoring()
        ollamaMonitor.startMonitoring()
    }

    /// Stops all background monitoring and pipeline tasks.
    func stop() {
        nowPlaying.stopPolling()
        orchestrator.stopListening()
        systemEQMonitor.stopMonitoring()
        ollamaMonitor.stopMonitoring()
        Task { await systemEQ.stopEngine() }
    }

    /// Dismisses onboarding without saving Spotify credentials.
    func skipOnboarding() {
        showOnboarding = false
    }

    /// Reopens the Spotify credential setup panel.
    func reopenSpotifySetup() {
        showOnboarding = true
    }

    private func bindOrchestratorCallbacks() {
        orchestrator.onStateChange = { [weak self] state in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.receivePipelineState(state)
            }
        }
        orchestrator.onProfileApplied = { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.handleProfileApplied(result)
            }
        }
    }

    private func bindMonitorCallbacks() {
        systemEQMonitor.onStatusChange = { [weak self] status in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.systemEQStatus = status
            }
        }
        ollamaMonitor.onAvailabilityChange = { [weak self] availability in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.ollamaAvailability = availability
                self.ollamaStatus = availability.connectionStatus
            }
        }
    }

    private func bindNowPlayingCallback() {
        nowPlaying.onTrackChange = { [weak self] track in
            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.handleTrackChange(track)
            }
        }
    }

    private func receivePipelineState(_ state: EQState) {
        pipelineState = state
        if case .error(let message) = state {
            errorMessage = message
        }
    }

    private func handleTrackChange(_ track: TrackInfo) async {
        currentTrack = track
        guard mode == .ai, isEQEnabled else { return }
        await orchestrator.processTrack(track)
    }

    private func handleProfileApplied(_ result: EQPipelineResult) {
        currentProfile = result.profile
        detectedGenres = result.genres
        eqSourceLabel = eqSourceLabel(for: result)
        manualProfile = EQProfileBridge.toEightBand(result.profile)
        errorMessage = nil
    }

    private func eqSourceLabel(for result: EQPipelineResult) -> String {
        if result.profileFromCache {
            return result.usedFallback ? "Cached fallback" : "Cached AI"
        }
        return result.usedFallback ? "Static fallback" : "Ollama AI"
    }

    private func handleModeTransition(from oldMode: EQfiMode, to newMode: EQfiMode) {
        if oldMode == .ai, newMode == .manual {
            freezeCurrentEQForManual()
            return
        }
        if oldMode == .manual, newMode == .ai {
            Task { await orchestrator.refreshCurrentTrack() }
        }
    }

    private func freezeCurrentEQForManual() {
        let profile = manualProfile ?? EQProfileBridge.toEightBand(currentProfile ?? .flat())
        manualViewModel.adoptProfile(profile)
    }

    private func handleEQToggle() async {
        isEngineTransitioning = true
        defer { isEngineTransitioning = false }
        orchestrator.setEnabled(isEQEnabled)
        if isEQEnabled {
            SystemAudioPermissionHelper.prepareUserForPermissionPrompt()
            needsSystemAudioPermission = false
            do {
                try await systemEQ.startEngine()
                try await systemEQ.applyProfile(activeEQProfile(), adaptiveEnabled: mode == .ai)
                if mode == .ai {
                    await orchestrator.refreshCurrentTrack()
                }
                needsSystemAudioPermission = false
                errorMessage = nil
            } catch {
                isEQEnabled = false
                orchestrator.setEnabled(false)
                let message = error.localizedDescription
                errorMessage = message
                needsSystemAudioPermission = message.localizedCaseInsensitiveContains("permission")
                    || message.localizedCaseInsensitiveContains("system audio")
            }
            return
        }
        needsSystemAudioPermission = false
        await systemEQ.stopEngine()
    }

    /// Opens the Ollama download page in the default browser.
    func openOllamaDownloadPage() {
        OllamaHelper.openDownloadPage()
    }

    /// Starts the local Ollama app or server process.
    func startOllama() {
        OllamaHelper.startOllama()
        ollamaMonitor.refreshNow()
    }

    /// Re-runs the AI EQ pipeline for the current track.
    func retryEQ() {
        guard mode == .ai else { return }
        Task { await orchestrator.retryCurrentTrack() }
    }

    /// Opens System Settings so the user can grant System Audio Recording access.
    func openSystemAudioSettings() {
        SystemAudioPermissionHelper.activateForPermissionPrompt()
        SystemAudioPermissionHelper.openSystemAudioRecordingSettings()
    }

    private func activeEQProfile() -> EQManualProfile {
        if mode == .manual {
            return EQManualProfile(
                bands: manualViewModel.bands,
                masterGain: manualViewModel.masterGain,
                presetName: manualViewModel.selectedPreset?.name
            )
        }
        return manualProfile ?? EQProfileBridge.toEightBand(currentProfile ?? .flat())
    }
}
