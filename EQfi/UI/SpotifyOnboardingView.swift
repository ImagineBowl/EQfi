//
//  SpotifyOnboardingView.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import AppKit
import SwiftUI

/// Inline Spotify credential form shown inside the menubar panel.
struct SpotifyOnboardingView: View {
    @Bindable var viewModel: EQViewModel
    @FocusState private var focusedField: Field?
    @State private var clientID = ""
    @State private var clientSecret = ""
    @State private var saveError: String?

    private let keychain: KeychainServiceProtocol

    private enum Field {
        case clientID
        case clientSecret
    }

    init(viewModel: EQViewModel, keychain: KeychainServiceProtocol) {
        self.viewModel = viewModel
        self.keychain = keychain
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            credentialFields
            if let saveError {
                Text(saveError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            actionButtons
        }
        .padding(4)
        .onAppear {
            activateForKeyboardInput()
            focusedField = .clientID
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Spotify Setup")
                .font(.title2.bold())
            Text("Enter your Spotify Client ID and Secret for genre lookup.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Create an app at developer.spotify.com. The account that owns the app needs Spotify Premium (Dev Mode). Add Redirect URI: http://127.0.0.1:8888/callback — do not use localhost.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var credentialFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("Client ID", text: $clientID)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .clientID)
            SecureField("Client Secret", text: $clientSecret)
                .textFieldStyle(.roundedBorder)
                .focused($focusedField, equals: .clientSecret)
        }
    }

    private var actionButtons: some View {
        HStack {
            Button("Skip for Now") { viewModel.skipOnboarding() }
            Spacer()
            Button("Save & Continue") { saveCredentials() }
                .keyboardShortcut(.defaultAction)
                .disabled(clientID.isEmpty || clientSecret.isEmpty)
        }
    }

    private func activateForKeyboardInput() {
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func saveCredentials() {
        let trimmedID = clientID.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedSecret = clientSecret.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedID.isEmpty, !trimmedSecret.isEmpty else {
            saveError = "Client ID and Secret are required."
            return
        }
        do {
            try keychain.save(trimmedID, forKey: Constants.Spotify.clientIDKey)
            try keychain.save(trimmedSecret, forKey: Constants.Spotify.clientSecretKey)
            viewModel.showOnboarding = false
            saveError = nil
        } catch {
            saveError = error.localizedDescription
        }
    }
}
