//
//  NowPlayingError.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Errors originating from now-playing detection.
enum NowPlayingError: Error, LocalizedError, Sendable {
    case scriptFailed(String)
    case noActivePlayer

    var errorDescription: String? {
        switch self {
        case .scriptFailed(let detail):
            return "Now playing detection failed: \(detail)."
        case .noActivePlayer:
            return "No active media player detected."
        }
    }
}
