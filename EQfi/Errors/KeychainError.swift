//
//  KeychainError.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Errors originating from Keychain read/write operations.
enum KeychainError: Error, LocalizedError, Sendable {
    case saveFailed(status: OSStatus)
    case readFailed(status: OSStatus)
    case deleteFailed(status: OSStatus)
    case unexpectedData

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to Keychain (status \(status))."
        case .readFailed(let status):
            return "Failed to read from Keychain (status \(status))."
        case .deleteFailed(let status):
            return "Failed to delete from Keychain (status \(status))."
        case .unexpectedData:
            return "Keychain returned data in an unexpected format."
        }
    }
}
