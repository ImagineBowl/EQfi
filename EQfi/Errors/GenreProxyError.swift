//
//  GenreProxyError.swift
//  EQfi
//
//  Created by Ahsan Minhas on 06/06/2026.
//

import Foundation

/// Errors originating from the hosted genre proxy API.
enum GenreProxyError: Error, LocalizedError, Sendable {
    case notConfigured
    case unauthorized
    case notFound
    case emptyResponse
    case invalidResponse(statusCode: Int)
    case decodingFailed(String)
    case networkFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Genre proxy is not configured."
        case .unauthorized:
            return "Genre proxy rejected the request (invalid API key)."
        case .notFound:
            return "Genre proxy could not find genres for this track."
        case .emptyResponse:
            return "Genre proxy returned no genres."
        case .invalidResponse(let statusCode):
            return "Genre proxy returned an unexpected status code: \(statusCode)."
        case .decodingFailed(let detail):
            return "Failed to decode genre proxy response: \(detail)."
        case .networkFailed(let detail):
            return "Genre proxy network request failed: \(detail)."
        }
    }
}
