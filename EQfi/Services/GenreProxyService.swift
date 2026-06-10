//
//  GenreProxyService.swift
//  EQfi
//
//  Created by Ahsan Minhas on 06/06/2026.
//

import Foundation

/// Fetches artist genres from the hosted EQfi genre proxy API.
final class GenreProxyService: PrimaryGenreLookupProtocol, @unchecked Sendable {
    private let cache: GenreCacheProtocol
    private let session: URLSession

    init(cache: GenreCacheProtocol, session: URLSession = .shared) {
        self.cache = cache
        self.session = session
    }

    /// Looks up genres for the given track via the genre proxy.
    func fetchGenre(for track: TrackInfo) async throws -> [String] {
        if let cached = cache.genre(forKey: track.cacheKey), !cached.isEmpty {
            PipelineLogger.genreProxyGenresResolved(cached, cached: true)
            return cached
        }
        let genres = try await requestGenres(title: track.title, artist: track.artist)
        cache.store(genres: genres, forKey: track.cacheKey)
        PipelineLogger.genreProxyGenresResolved(genres, cached: false)
        return genres
    }

    private func requestGenres(title: String, artist: String) async throws -> [String] {
        guard let baseURL = Constants.GenreProxy.baseURL else {
            throw GenreProxyError.notConfigured
        }
        guard !Constants.GenreProxy.apiKey.isEmpty else {
            throw GenreProxyError.notConfigured
        }

        var components = URLComponents(url: baseURL.appendingPathComponent("v1/genre"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "artist", value: artist)
        ]
        guard let url = components?.url else {
            throw GenreProxyError.notConfigured
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(Constants.GenreProxy.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue(Constants.GenreProxy.userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = Constants.GenreProxy.requestTimeoutSeconds

        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response)
            return try parseGenres(from: data)
        } catch let error as GenreProxyError {
            throw error
        } catch {
            throw GenreProxyError.networkFailed(error.localizedDescription)
        }
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw GenreProxyError.invalidResponse(statusCode: -1)
        }
        switch http.statusCode {
        case 200:
            return
        case 401:
            throw GenreProxyError.unauthorized
        case 404:
            throw GenreProxyError.notFound
        default:
            throw GenreProxyError.invalidResponse(statusCode: http.statusCode)
        }
    }

    private func parseGenres(from data: Data) throws -> [String] {
        do {
            let decoded = try JSONDecoder().decode(GenreProxyResponse.self, from: data)
            guard !decoded.genres.isEmpty else { throw GenreProxyError.emptyResponse }
            return decoded.genres
        } catch let error as GenreProxyError {
            throw error
        } catch {
            throw GenreProxyError.decodingFailed(error.localizedDescription)
        }
    }
}

/// JSON payload from `GET /v1/genre`.
struct GenreProxyResponse: Decodable, Sendable {
    let genres: [String]
    let source: String?
}
