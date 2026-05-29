//
//  AudioFeatures.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Real-time spectral and loudness measurements from playing audio.
/// Structured for adaptive EQ today and LLM prompts later.
struct AudioFeatures: Codable, Sendable, Equatable {
    /// Normalized low-end energy (0...1).
    let bassEnergy: Float
    /// Normalized high-end energy (0...1).
    let trebleEnergy: Float
    /// RMS level in dBFS (typically -60...0).
    let rmsLoudnessDB: Float
    /// Spectral centroid in Hz.
    let spectralCentroidHz: Float
    /// Short-term vs long-term RMS spread in dB.
    let dynamicRangeDB: Float
    /// Normalized upper-mid harshness in 2–5 kHz (0...1).
    let harshness: Float
    let capturedAt: Date

    /// Compact summary suitable for future Ollama prompts.
    var llmSummary: String {
        """
        bass=\(String(format: "%.2f", bassEnergy)), \
        treble=\(String(format: "%.3f", trebleEnergy)), \
        rms=\(String(format: "%.1f", rmsLoudnessDB))dBFS, \
        centroid=\(Int(spectralCentroidHz))Hz, \
        dynamics=\(String(format: "%.1f", dynamicRangeDB))dB, \
        harshness=\(String(format: "%.2f", harshness))
        """
    }
}
