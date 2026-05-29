//
//  WhyThisEQView.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import SwiftUI

/// Popover explaining the AI-generated EQ reasoning.
struct WhyThisEQView: View {
    let profile: EQProfile?
    let genres: [String]
    let eqSourceLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Why this EQ?")
                .font(.headline)
            if !genres.isEmpty, genres != ["unknown"] {
                Text("Genre: \(genres.joined(separator: ", "))")
                    .font(.subheadline)
            } else {
                Text("Genre: not detected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if let profile {
                Text("Preset: \(profile.presetName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !eqSourceLabel.isEmpty {
                Text("Source: \(eqSourceLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(reasoningText)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 300)
    }

    private var reasoningText: String {
        profile?.reasoning ?? "EQ was chosen based on detected genre and output device."
    }
}
