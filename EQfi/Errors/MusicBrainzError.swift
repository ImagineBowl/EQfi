//
//  MusicBrainzError.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Errors originating from MusicBrainz API interactions.
enum MusicBrainzError: Error, LocalizedError, Sendable {
    case artistNotFound
    case noTagsFound
    case invalidResponse(statusCode: Int)
    case networkFailed(String)

    var errorDescription: String? {
        switch self {
        case .artistNotFound:
            return "Artist was not found on MusicBrainz."
        case .noTagsFound:
            return "No genre tags found for this artist on MusicBrainz."
        case .invalidResponse(let statusCode):
            return "MusicBrainz returned an unexpected status code: \(statusCode)."
        case .networkFailed(let detail):
            return "MusicBrainz network request failed: \(detail)."
        }
    }
}
