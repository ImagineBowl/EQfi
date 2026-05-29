//
//  SystemEQError.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Errors originating from native system audio EQ processing.
enum SystemEQError: Error, LocalizedError, Sendable {
    case unsupportedOSVersion
    case tapCreationFailed(status: OSStatus)
    case aggregateDeviceFailed(status: OSStatus)
    case tapAssignmentFailed(status: OSStatus)
    case engineStartFailed(String)
    case engineNotRunning
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .unsupportedOSVersion:
            return "System-wide EQ requires macOS 14.2 or later."
        case .tapCreationFailed(let status):
            return "Failed to create audio tap (status \(status))."
        case .aggregateDeviceFailed(let status):
            return "Failed to create aggregate audio device (status \(status))."
        case .tapAssignmentFailed(let status):
            return "Failed to assign audio tap (status \(status))."
        case .engineStartFailed(let detail):
            return "Failed to start EQ engine: \(detail)"
        case .engineNotRunning:
            return "EQ engine is not running."
        case .permissionDenied:
            return "Grant System Audio Recording permission in System Settings."
        }
    }
}
