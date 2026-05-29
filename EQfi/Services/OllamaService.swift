//
//  OllamaService.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Generates EQ profiles by prompting a local Ollama Llama 3.2 model.
final class OllamaService: OllamaServiceProtocol, @unchecked Sendable {
    private let session: URLSession
    private let validator: EQProfileValidator
    private let modelResolver: OllamaModelResolver

    init(
        session: URLSession = .shared,
        validator: EQProfileValidator = EQProfileValidator(),
        modelResolver: OllamaModelResolver = OllamaModelResolver()
    ) {
        self.session = session
        self.validator = validator
        self.modelResolver = modelResolver
    }

    /// Produces a five-band EQ profile for the given genre and output device.
    func generateEQProfile(genre: String, device: AudioDevice) async throws -> EQProfile {
        guard let url = Constants.Ollama.generateURL else {
            throw OllamaError.unreachable
        }
        let model = try await modelResolver.resolveModel()
        PipelineLogger.ollamaUsingModel(model)
        let body = buildRequestBody(genre: genre, device: device.displayName, model: model)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = Constants.Ollama.requestTimeoutSeconds
        let rawText = try await performGenerate(request)
        return try validator.validate(rawResponse: rawText, presetName: genre)
    }

    private func buildRequestBody(genre: String, device: String, model: String) -> Data? {
        let prompt = Constants.Ollama.promptTemplate(genre: genre, device: device)
        let payload = OllamaGenerateRequest(
            model: model,
            prompt: prompt,
            stream: false,
            format: "json"
        )
        return try? JSONEncoder().encode(payload)
    }

    private func performGenerate(_ request: URLRequest) async throws -> String {
        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response)
            return try parseResponse(data)
        } catch let error as OllamaError {
            throw error
        } catch {
            throw OllamaError.networkFailed(error.localizedDescription)
        }
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw OllamaError.invalidResponse(statusCode: -1)
        }
        guard http.statusCode == 200 else {
            throw OllamaError.invalidResponse(statusCode: http.statusCode)
        }
    }

    private func parseResponse(_ data: Data) throws -> String {
        do {
            let decoded = try JSONDecoder().decode(OllamaGenerateResponse.self, from: data)
            guard !decoded.response.isEmpty else { throw OllamaError.emptyResponse }
            return decoded.response
        } catch let error as OllamaError {
            throw error
        } catch {
            throw OllamaError.decodingFailed(error.localizedDescription)
        }
    }
}

private struct OllamaGenerateRequest: Encodable {
    let model: String
    let prompt: String
    let stream: Bool
    let format: String
}

private struct OllamaGenerateResponse: Decodable {
    let response: String
}
