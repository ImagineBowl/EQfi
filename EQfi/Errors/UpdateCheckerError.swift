//
//  UpdateCheckerError.swift
//  EQfi
//
//  Created by Ahsan Minhas on 11/06/2026.
//

import Foundation

/// Errors originating from GitHub release update checks.
enum UpdateCheckerError: Error, Sendable {
    case invalidConfiguration
    case invalidResponse(statusCode: Int)
}
