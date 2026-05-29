//
//  OllamaModelResolver.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Resolves an installed Ollama model name from the local tags API.
actor OllamaModelResolver {
    private let session: URLSession
    private var cachedModel: String?

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Returns the best locally installed model for EQ generation.
    func resolveModel() async throws -> String {
        if let cached = cachedModel { return cached }
        let model = try await fetchBestModel()
        cachedModel = model
        return model
    }

    /// Returns whether a usable model is installed.
    func hasUsableModel() async -> Bool {
        (try? await resolveModel()) != nil
    }

    private func fetchBestModel() async throws -> String {
        guard let url = Constants.Ollama.tagsURL else { throw OllamaError.unreachable }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 3
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw OllamaError.unreachable
        }
        let names = try parseModelNames(from: data)
        guard let match = selectModel(from: names) else {
            throw OllamaError.modelNotFound(preferred: Constants.Ollama.modelName)
        }
        return match
    }

    private func parseModelNames(from data: Data) throws -> [String] {
        let decoded = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
        return decoded.models.map(\.name)
    }

    private func selectModel(from names: [String]) -> String? {
        for prefix in Constants.Ollama.modelFallbackPrefixes {
            if let exact = names.first(where: { $0 == prefix }) { return exact }
            if let tagged = names.first(where: { $0.hasPrefix("\(prefix):") }) { return tagged }
        }
        return names.first
    }
}

private struct OllamaTagsResponse: Decodable {
    struct Model: Decodable {
        let name: String
    }

    let models: [Model]
}
