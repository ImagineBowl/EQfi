//
//  EQState.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Pipeline lifecycle state for the AI orchestrator.
enum EQState: Sendable, Equatable {
    case idle
    case detecting
    case applying
    case error(message: String)
}
