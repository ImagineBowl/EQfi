//
//  OllamaModelResolver.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Resolves an Ollama model name, preferring a loaded Llama model over installed tags.
actor OllamaModelResolver {
    private let session: URLSession
    private var cachedInstalledModel: String?

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Returns the best model for EQ generation.
    func resolveModel() async throws -> String {
        if let loaded = try await fetchLoadedModel() {
            return loaded
        }
        if let cached = cachedInstalledModel { return cached }
        let model = try await fetchBestInstalledModel()
        cachedInstalledModel = model
        return model
    }

    /// Returns whether a usable model is available.
    func hasUsableModel() async -> Bool {
        (try? await resolveModel()) != nil
    }

    private func fetchLoadedModel() async throws -> String? {
        guard let url = Constants.Ollama.psURL else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 3
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
        let names = try parseLoadedModelNames(from: data)
        return OllamaModelPicker.selectBest(from: names)
    }

    private func fetchBestInstalledModel() async throws -> String {
        guard let url = Constants.Ollama.tagsURL else { throw OllamaError.unreachable }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 3
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw OllamaError.unreachable
        }
        let names = try parseInstalledModelNames(from: data)
        guard let match = OllamaModelPicker.selectBest(from: names) else {
            throw OllamaError.modelNotFound(preferred: Constants.Ollama.modelName)
        }
        return match
    }

    private func parseLoadedModelNames(from data: Data) throws -> [String] {
        let decoded = try JSONDecoder().decode(OllamaPsResponse.self, from: data)
        return decoded.models.map(\.model)
    }

    private func parseInstalledModelNames(from data: Data) throws -> [String] {
        let decoded = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
        return decoded.models.map(\.name)
    }
}

private struct OllamaPsResponse: Decodable {
    struct Model: Decodable {
        let model: String
    }

    let models: [Model]
}

private struct OllamaTagsResponse: Decodable {
    struct Model: Decodable {
        let name: String
    }

    let models: [Model]
}
