//
//  SpotifyError.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Errors originating from Spotify Web API interactions.
enum SpotifyError: Error, LocalizedError, Sendable {
    case missingCredentials
    case tokenFetchFailed
    case trackNotFound
    case artistNotFound
    case premiumRequired(String)
    case rateLimited(retryAfter: TimeInterval)
    case apiError(statusCode: Int, message: String)
    case invalidResponse(statusCode: Int)
    case decodingFailed(String)
    case networkFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingCredentials:
            return "Spotify credentials are not configured."
        case .tokenFetchFailed:
            return "Failed to obtain a Spotify access token."
        case .trackNotFound:
            return "Track was not found on Spotify."
        case .artistNotFound:
            return "Artist was not found on Spotify."
        case .premiumRequired(let detail):
            return detail
        case .rateLimited(let retryAfter):
            return "Spotify rate limit exceeded. Retry in \(Int(retryAfter)) seconds."
        case .apiError(let statusCode, let message):
            return "Spotify API error (\(statusCode)): \(message)"
        case .invalidResponse(let statusCode):
            return "Spotify returned an unexpected status code: \(statusCode)."
        case .decodingFailed(let detail):
            return "Failed to decode Spotify response: \(detail)."
        case .networkFailed(let detail):
            return "Spotify network request failed: \(detail)."
        }
    }
}
