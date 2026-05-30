//
//  MenuBarView.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import AppKit
import SwiftUI

/// Root menubar popover content driven by the main ViewModel.
struct MenuBarView: View {
    @Bindable var viewModel: EQViewModel
    let keychain: KeychainServiceProtocol
    @State private var showWhyEQ = false

    var body: some View {
        Group {
            if viewModel.showOnboarding {
                SpotifyOnboardingView(viewModel: viewModel, keychain: keychain)
            } else {
                mainContent
            }
        }
        .padding(16)
        .frame(width: panelWidth)
        .fixedSize(horizontal: true, vertical: false)
        .id(panelIdentity)
        .onAppear { NSApplication.shared.activate(ignoringOtherApps: true) }
    }

    private var panelWidth: CGFloat {
        if viewModel.showOnboarding { return 380 }
        return viewModel.mode == .manual ? 520 : 320
    }

    private var panelIdentity: String {
        if viewModel.showOnboarding { return "onboarding" }
        return viewModel.mode == .manual ? "manual" : "ai"
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            ModeToggleView(viewModel: viewModel)
            trackSection
            if let error = viewModel.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red)
            }
            if viewModel.mode == .ai { aiSection } else { manualSection }
            statusSection
            footerSection
        }
        .popover(isPresented: $showWhyEQ) {
            WhyThisEQView(
                profile: viewModel.currentProfile,
                genres: viewModel.detectedGenres,
                eqSourceLabel: viewModel.eqSourceLabel
            )
        }
    }

    @ViewBuilder
    private var trackSection: some View {
        if let track = viewModel.currentTrack {
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title).font(.headline).lineLimit(1)
                Text(track.artist).font(.subheadline).foregroundStyle(.secondary)
            }
        } else {
            Text("No track playing").foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var aiSection: some View {
        genreBadge
        if let profile = viewModel.currentProfile {
            Text("Preset: \(profile.presetName)").font(.caption)
            EQBarsView(gains: profile.bandGains)
        }
        Toggle("Enable EQfi", isOn: Binding(
            get: { viewModel.isEQEnabled },
            set: { _ in viewModel.toggleEQEnabled() }
        ))
        HStack {
            Button("Why this EQ?") { showWhyEQ = true }
            Spacer()
            retryEQButton
        }
    }

    @ViewBuilder
    private var manualSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Enable EQfi", isOn: Binding(
                get: { viewModel.isEQEnabled },
                set: { _ in viewModel.toggleEQEnabled() }
            ))
            ManualEQPanelView(manualViewModel: viewModel.manualViewModel)
        }
    }

    @ViewBuilder
    private var genreBadge: some View {
        if let label = genreDisplayLabel {
            Text(label)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary, in: Capsule())
        }
    }

    private var genreDisplayLabel: String? {
        let genres = viewModel.detectedGenres.filter { $0 != "unknown" }
        if genres.isEmpty {
            return viewModel.detectedGenres.contains("unknown") ? "Genre not detected" : nil
        }
        return genres.joined(separator: ", ")
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                StatusDotView(label: "Ollama", status: viewModel.ollamaStatus)
                StatusDotView(label: "System EQ", status: viewModel.systemEQStatus)
            }
            serviceHintText
        }
    }

    @ViewBuilder
    private var serviceHintText: some View {
        if viewModel.mode == .manual { EmptyView() }
        else if viewModel.needsSystemAudioPermission {
            VStack(alignment: .leading, spacing: 6) {
                Text("EQfi needs System Audio Recording permission. When you enable EQ, click Allow in the macOS prompt. EQfi will then appear under System Audio Recording Only in System Settings.")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                Button("Open System Settings") {
                    viewModel.openSystemAudioSettings()
                }
                .font(.caption)
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                if !viewModel.isEQEnabled {
                    Text("Toggle Enable EQfi to start system audio processing. macOS will ask for System Audio Recording permission the first time.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else if viewModel.systemEQStatus == .disconnected {
                    Text("System EQ is not active. Grant System Audio Recording permission if prompted.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                ollamaHintSection
            }
        }
    }

    @ViewBuilder
    private var ollamaHintSection: some View {
        switch viewModel.ollamaAvailability {
        case .ready:
            if isUsingFallback {
                Text("Using a static fallback EQ profile. Tap Re-EQ after starting Ollama.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        case .notInstalled:
            VStack(alignment: .leading, spacing: 6) {
                Text("Ollama is not installed. Download it to generate AI EQ profiles for each track.")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                Button("Download Ollama") {
                    viewModel.openOllamaDownloadPage()
                }
                .font(.caption)
            }
        case .notRunning:
            VStack(alignment: .leading, spacing: 6) {
                Text("Ollama is installed but not running. Start it, then tap Re-EQ.")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                Button("Start Ollama") {
                    viewModel.startOllama()
                }
                .font(.caption)
            }
        case .noModel:
            Text("Ollama is running but no compatible model is installed. Run `ollama pull \(Constants.Ollama.modelName)` in Terminal, then tap Re-EQ.")
                .font(.caption2)
                .foregroundStyle(.orange)
        }
    }

    private var isUsingFallback: Bool {
        viewModel.eqSourceLabel.localizedCaseInsensitiveContains("fallback")
    }

    private var isPipelineBusy: Bool {
        switch viewModel.pipelineState {
        case .detecting, .applying: return true
        case .idle, .error: return false
        }
    }

    private var retryEQButton: some View {
        Button(isPipelineBusy ? "Re-EQ…" : "Re-EQ") {
            viewModel.retryEQ()
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
        .disabled(isPipelineBusy)
    }

    private var footerSection: some View {
        HStack {
            Button("Spotify Settings") { viewModel.reopenSpotifySetup() }
                .font(.caption)
            Spacer()
            Button("Quit") { NSApplication.shared.terminate(nil) }
        }
    }
}
