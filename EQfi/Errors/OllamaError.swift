//
//  OllamaError.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Errors originating from local Ollama API interactions.
enum OllamaError: Error, LocalizedError, Sendable {
    case unreachable
    case modelNotFound(preferred: String)
    case invalidResponse(statusCode: Int)
    case decodingFailed(String)
    case validationFailed(String)
    case emptyResponse
    case networkFailed(String)

    var errorDescription: String? {
        switch self {
        case .unreachable:
            return "Ollama is not running on localhost."
        case .modelNotFound(let preferred):
            return "No Ollama model matching '\(preferred)' is installed. Run: ollama pull \(preferred)"
        case .invalidResponse(let statusCode):
            if statusCode == 404 {
                return "Ollama model not found. Install one with: ollama pull llama3.2"
            }
            return "Ollama returned an unexpected status code: \(statusCode)."
        case .decodingFailed(let detail):
            return "Failed to decode Ollama response: \(detail)."
        case .validationFailed(let detail):
            return "Ollama EQ profile failed validation: \(detail)."
        case .emptyResponse:
            return "Ollama returned an empty response."
        case .networkFailed(let detail):
            return "Ollama network request failed: \(detail)."
        }
    }
}
