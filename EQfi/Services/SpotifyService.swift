//
//  SpotifyService.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Fetches artist genres from Spotify using client-credentials OAuth.
final class SpotifyService: SpotifyServiceProtocol, @unchecked Sendable {
    private let tokenManager: SpotifyTokenManager
    private let cache: GenreCacheProtocol
    private let session: URLSession

    init(
        tokenManager: SpotifyTokenManager,
        cache: GenreCacheProtocol,
        session: URLSession = .shared
    ) {
        self.tokenManager = tokenManager
        self.cache = cache
        self.session = session
    }

    /// Looks up genres for the given track via search and artist metadata.
    func fetchGenre(for track: TrackInfo) async throws -> [String] {
        if let cached = cache.genre(forKey: track.cacheKey), !cached.isEmpty {
            PipelineLogger.spotifyGenresResolved(cached, cached: true)
            return cached
        }
        let token = try await tokenManager.validToken()
        let artistID = try await resolveArtistID(for: track, token: token)
        let genres = try await fetchArtistGenres(artistID: artistID, token: token)
        cache.store(genres: genres, forKey: track.cacheKey)
        PipelineLogger.spotifyGenresResolved(genres, cached: false)
        return genres
    }

    /// Refreshes the client-credentials token when expired or missing.
    func refreshTokenIfNeeded() async throws {
        _ = try await tokenManager.validToken()
    }

    private func resolveArtistID(for track: TrackInfo, token: String) async throws -> String {
        let cleanedTitle = sanitizeSearchText(track.title)
        let cleanedArtist = sanitizeSearchText(primaryArtist(from: track.artist))

        let trackQuery = "track:\(cleanedTitle) artist:\(cleanedArtist)"
        do {
            return try await searchTrackArtistID(query: trackQuery, token: token)
        } catch {
            PipelineLogger.spotifyFailed("Track search failed (\(error.localizedDescription)). Trying artist search.")
        }

        do {
            return try await searchArtistID(name: cleanedArtist, token: token)
        } catch {
            PipelineLogger.spotifyFailed("Artist search failed (\(error.localizedDescription)). Trying title-only search.")
        }

        let titleQuery = "track:\(cleanedTitle)"
        return try await searchTrackArtistID(query: titleQuery, token: token)
    }

    private func searchTrackArtistID(query: String, token: String) async throws -> String {
        guard let base = Constants.Spotify.apiBaseURL else { throw SpotifyError.networkFailed("Invalid base URL") }
        var components = URLComponents(url: base.appendingPathComponent("search"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "track"),
            URLQueryItem(name: "limit", value: "1"),
            URLQueryItem(name: "market", value: Constants.Spotify.defaultMarket)
        ]
        guard let url = components?.url else {
            throw SpotifyError.networkFailed("Invalid search URL")
        }
        let data = try await authorizedGET(url: url, token: token)
        return try parseTrackArtistID(from: data)
    }

    private func searchArtistID(name: String, token: String) async throws -> String {
        guard let base = Constants.Spotify.apiBaseURL else { throw SpotifyError.networkFailed("Invalid base URL") }
        var components = URLComponents(url: base.appendingPathComponent("search"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "q", value: name),
            URLQueryItem(name: "type", value: "artist"),
            URLQueryItem(name: "limit", value: "1"),
            URLQueryItem(name: "market", value: Constants.Spotify.defaultMarket)
        ]
        guard let url = components?.url else {
            throw SpotifyError.networkFailed("Invalid artist search URL")
        }
        let data = try await authorizedGET(url: url, token: token)
        return try parseArtistSearchID(from: data)
    }

    private func parseTrackArtistID(from data: Data) throws -> String {
        do {
            let response = try JSONDecoder().decode(SpotifySearchResponse.self, from: data)
            guard let artistID = response.tracks.items.first?.artists.first?.id else {
                throw SpotifyError.trackNotFound
            }
            return artistID
        } catch let error as SpotifyError {
            throw error
        } catch {
            throw SpotifyError.decodingFailed(error.localizedDescription)
        }
    }

    private func parseArtistSearchID(from data: Data) throws -> String {
        do {
            let response = try JSONDecoder().decode(SpotifyArtistSearchResponse.self, from: data)
            guard let artistID = response.artists.items.first?.id else {
                throw SpotifyError.artistNotFound
            }
            return artistID
        } catch let error as SpotifyError {
            throw error
        } catch {
            throw SpotifyError.decodingFailed(error.localizedDescription)
        }
    }

    private func fetchArtistGenres(artistID: String, token: String) async throws -> [String] {
        guard let base = Constants.Spotify.apiBaseURL else {
            throw SpotifyError.networkFailed("Invalid base URL")
        }
        let url = base.appendingPathComponent("artists/\(artistID)")
        let data = try await authorizedGET(url: url, token: token)
        return try parseGenres(from: data)
    }

    private func parseGenres(from data: Data) throws -> [String] {
        do {
            let response = try JSONDecoder().decode(SpotifyArtistResponse.self, from: data)
            guard !response.genres.isEmpty else { throw SpotifyError.artistNotFound }
            return response.genres
        } catch let error as SpotifyError {
            throw error
        } catch {
            throw SpotifyError.decodingFailed(error.localizedDescription)
        }
    }

    private func sanitizeSearchText(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\"", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func primaryArtist(from artistField: String) -> String {
        TrackInfo(title: "", artist: artistField, source: .spotify, isPodcast: false).primaryArtistName
    }

    private func authorizedGET(url: URL, token: String) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return try await performRequest(request)
    }

    private func performRequest(_ request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response, body: data)
            return data
        } catch let error as SpotifyError {
            throw error
        } catch {
            throw SpotifyError.networkFailed(error.localizedDescription)
        }
    }

    private func validateResponse(_ response: URLResponse, body: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw SpotifyError.invalidResponse(statusCode: -1)
        }
        if http.statusCode == 429 {
            let retry = http.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init) ?? 60
            throw SpotifyError.rateLimited(retryAfter: retry)
        }
        guard http.statusCode == 200 else {
            let message = Self.parseErrorMessage(from: body)
            if http.statusCode == 403, let message, message.lowercased().contains("premium") {
                throw SpotifyError.premiumRequired(
                    "Spotify requires Premium on the developer account that owns this app. \(message)"
                )
            }
            throw SpotifyError.apiError(
                statusCode: http.statusCode,
                message: message ?? "HTTP \(http.statusCode)"
            )
        }
    }

    private static func parseErrorMessage(from body: Data) -> String? {
        guard let decoded = try? JSONDecoder().decode(SpotifyAPIErrorResponse.self, from: body) else {
            return String(data: body, encoding: .utf8)
        }
        return decoded.error.message
    }
}

private struct SpotifyAPIErrorResponse: Decodable {
    struct ErrorBody: Decodable {
        let status: Int
        let message: String
    }

    let error: ErrorBody
}
