//
//  EQPipelineResult.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Outcome of a full AI pipeline pass for one track.
struct EQPipelineResult: Sendable {
    let profile: EQProfile
    let genres: [String]
    let usedFallback: Bool
    let profileFromCache: Bool
}
