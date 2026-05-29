//
//  OllamaServiceProtocol.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Generates EQ profiles using a locally running Ollama model.
protocol OllamaServiceProtocol: Sendable {
    /// Produces a five-band EQ profile for the given genre and output device.
    func generateEQProfile(genre: String, device: AudioDevice) async throws -> EQProfile
}
