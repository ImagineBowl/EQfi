//
//  EQProfileValidator.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Validates and parses Ollama JSON responses into EQ profiles.
struct EQProfileValidator {
    private let minGain = Constants.EQProfileLimits.gainMin
    private let maxGain = Constants.EQProfileLimits.gainMax

    /// Parses raw Ollama text and validates all five band gains.
    func validate(rawResponse: String, presetName: String) throws -> EQProfile {
        let jsonString = extractJSON(from: rawResponse)
        let bands = try decodeBands(from: jsonString)
        try validateBandRange(bands)
        return buildProfile(from: bands, presetName: presetName)
    }

    private func extractJSON(from text: String) -> String {
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let start = cleaned.firstIndex(of: "{"), let end = cleaned.lastIndex(of: "}") else {
            return cleaned
        }
        return String(cleaned[start...end])
    }

    private func decodeBands(from json: String) throws -> OllamaBandPayload {
        guard let data = json.data(using: .utf8) else {
            throw OllamaError.decodingFailed("Invalid UTF-8 data.")
        }
        do {
            return try JSONDecoder().decode(OllamaBandPayload.self, from: data)
        } catch {
            throw OllamaError.decodingFailed(error.localizedDescription)
        }
    }

    private func validateBandRange(_ bands: OllamaBandPayload) throws {
        let values = [bands.subBass, bands.bass, bands.midrange, bands.presence, bands.brilliance]
        for value in values where value < minGain || value > maxGain {
            throw OllamaError.validationFailed("Gain \(value) is outside \(minGain)...\(maxGain) dB.")
        }
    }

    private func buildProfile(from bands: OllamaBandPayload, presetName: String) -> EQProfile {
        EQProfile(
            subBass: bands.subBass,
            bass: bands.bass,
            midrange: bands.midrange,
            presence: bands.presence,
            brilliance: bands.brilliance,
            presetName: presetName,
            reasoning: bands.reasoning
        )
    }
}

/// Decodable five-band payload from Ollama JSON output.
struct OllamaBandPayload: Decodable, Sendable {
    let subBass: Float
    let bass: Float
    let midrange: Float
    let presence: Float
    let brilliance: Float
    let reasoning: String?

    enum CodingKeys: String, CodingKey {
        case subBass = "sub_bass"
        case bass
        case midrange
        case presence
        case brilliance
        case reasoning
    }
}
