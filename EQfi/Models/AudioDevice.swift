//
//  AudioDevice.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Describes the active audio output device used for EQ tuning context.
enum AudioDevice: String, Codable, Sendable, CaseIterable {
    case headphones
    case speakers
    case external
    case unknown

    /// Human-readable label shown in prompts and UI.
    var displayName: String {
        switch self {
        case .headphones: return "Headphones"
        case .speakers: return "Built-in Speakers"
        case .external: return "External Output"
        case .unknown: return "Unknown Device"
        }
    }
}
