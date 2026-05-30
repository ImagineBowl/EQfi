//
//  OllamaAvailability.swift
//  EQfi
//
//  Created by Ahsan Minhas on 29/05/2026.
//

import Foundation

/// Detailed Ollama runtime state for menubar actions and hints.
enum OllamaAvailability: Sendable, Equatable {
    case ready
    case notInstalled
    case notRunning
    case noModel

    var connectionStatus: ServiceConnectionStatus {
        switch self {
        case .ready: return .connected
        case .noModel: return .degraded
        case .notInstalled, .notRunning: return .disconnected
        }
    }
}
