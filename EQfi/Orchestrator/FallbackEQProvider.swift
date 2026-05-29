//
//  FallbackEQProvider.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Static genre-to-EQ fallback map used when Ollama is unavailable.
struct FallbackEQProvider {
    /// Returns a fallback EQ profile for the given genre labels.
    static func profile(for genres: [String]) -> EQProfile {
        let combined = genres.joined(separator: " ").lowercased()
        if combined.contains("podcast") || combined.contains("spoken") { return podcast }
        if matchesRock(combined) { return rock }
        if combined.contains("pop") { return pop }
        if combined.contains("jazz") { return jazz }
        if combined.contains("classical") || combined.contains("orchestra") { return classical }
        if combined.contains("hip") || combined.contains("rap") || combined.contains("trap") { return hiphop }
        if combined.contains("electronic") || combined.contains("edm") || combined.contains("house") {
            return electronic
        }
        return unknown
    }

    /// Returns a fallback EQ profile for a single genre label.
    static func profile(for genre: String) -> EQProfile {
        profile(for: [genre])
    }

    private static func matchesRock(_ label: String) -> Bool {
        label.contains("rock")
            || label.contains("metal")
            || label.contains("alternative")
            || label.contains("punk")
            || label.contains("grunge")
    }

    private static let rock = EQProfile(
        subBass: 2, bass: 4, midrange: -1, presence: 3, brilliance: 2,
        presetName: "Rock Fallback", reasoning: "Static fallback preset tuned for rock and metal."
    )

    private static let pop = EQProfile(
        subBass: 1, bass: 2, midrange: 0, presence: 2, brilliance: 3,
        presetName: "Pop Fallback", reasoning: "Static fallback preset tuned for pop."
    )

    private static let jazz = EQProfile(
        subBass: 1, bass: 2, midrange: 3, presence: 1, brilliance: 1,
        presetName: "Jazz Fallback", reasoning: "Static fallback preset tuned for jazz."
    )

    private static let classical = EQProfile(
        subBass: 0, bass: 1, midrange: 2, presence: 2, brilliance: 3,
        presetName: "Classical Fallback", reasoning: "Static fallback preset tuned for classical."
    )

    private static let hiphop = EQProfile(
        subBass: 5, bass: 5, midrange: -1, presence: 2, brilliance: 1,
        presetName: "Hip-Hop Fallback", reasoning: "Static fallback preset tuned for hip-hop."
    )

    private static let electronic = EQProfile(
        subBass: 4, bass: 3, midrange: -2, presence: 2, brilliance: 3,
        presetName: "Electronic Fallback", reasoning: "Static fallback preset tuned for electronic music."
    )

    private static let podcast = EQProfile(
        subBass: -3, bass: -1, midrange: 5, presence: 4, brilliance: 2,
        presetName: "Podcast Fallback", reasoning: "Static fallback preset tuned for speech."
    )

    private static let unknown = EQProfile(
        subBass: 0, bass: 0, midrange: 0, presence: 0, brilliance: 0,
        presetName: "Flat Fallback", reasoning: "No genre detected — using a flat fallback preset."
    )
}
