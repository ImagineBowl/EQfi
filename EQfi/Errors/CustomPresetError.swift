//
//  CustomPresetError.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Errors originating from custom preset persistence.
enum CustomPresetError: Error, LocalizedError, Sendable {
    case notFound(name: String)
    case encodingFailed(String)
    case decodingFailed(String)
    case duplicateName(name: String)

    var errorDescription: String? {
        switch self {
        case .notFound(let name):
            return "Custom preset '\(name)' was not found."
        case .encodingFailed(let detail):
            return "Failed to encode preset: \(detail)."
        case .decodingFailed(let detail):
            return "Failed to decode preset: \(detail)."
        case .duplicateName(let name):
            return "A preset named '\(name)' already exists."
        }
    }
}
