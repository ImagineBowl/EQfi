//
//  CachedEQProfile.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Persisted EQ pipeline output for a track and output device.
struct CachedEQProfile: Codable, Sendable, Equatable {
    let profile: EQProfile
    let usedFallback: Bool
}
