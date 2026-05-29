//
//  EQBand.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// A single frequency band in the manual 8-band equalizer.
struct EQBand: Codable, Sendable, Equatable, Identifiable {
    let frequency: Int
    let label: String
    var gain: Float

    var id: Int { frequency }

    /// Compact frequency label for slider UI (e.g. 1k, 8k).
    var frequencyLabel: String {
        if frequency >= 1_000 {
            return "\(frequency / 1_000)k"
        }
        return "\(frequency)"
    }

    /// Shorter band name for narrow slider columns.
    var shortLabel: String {
        switch label {
        case "Sub Bass": return "Sub"
        case "Upper Bass": return "Up Bass"
        case "Low Midrange": return "Lo Mid"
        case "Upper Midrange": return "Up Mid"
        default: return label
        }
    }

    /// Standard eight-band configuration used across manual mode.
    static let standardBands: [EQBand] = [
        EQBand(frequency: 32, label: "Sub Bass", gain: 0),
        EQBand(frequency: 64, label: "Bass", gain: 0),
        EQBand(frequency: 125, label: "Upper Bass", gain: 0),
        EQBand(frequency: 250, label: "Low Midrange", gain: 0),
        EQBand(frequency: 500, label: "Midrange", gain: 0),
        EQBand(frequency: 1_000, label: "Upper Midrange", gain: 0),
        EQBand(frequency: 8_000, label: "Presence", gain: 0),
        EQBand(frequency: 16_000, label: "Brilliance", gain: 0)
    ]
}
