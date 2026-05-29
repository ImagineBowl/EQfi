//
//  MusicBrainzService.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Fetches artist genre tags from the free MusicBrainz API.
final class MusicBrainzService: GenreLookupFallbackProtocol, @unchecked Sendable {
    private let cache: GenreCacheProtocol
    private let session: URLSession

    init(cache: GenreCacheProtocol, session: URLSession = .shared) {
        self.cache = cache
        self.session = session
    }

    /// Looks up genre tags for the track's primary artist.
    func fetchGenre(for track: TrackInfo) async throws -> [String] {
        if let cached = cache.genre(forKey: track.cacheKey), !cached.isEmpty {
            PipelineLogger.musicBrainzGenresResolved(cached, cached: true)
            return cached
        }
        let artistName = track.primaryArtistName
        let artistID = try await searchArtistID(name: artistName)
        let tags = try await fetchArtistTags(artistID: artistID)
        cache.store(genres: tags, forKey: track.cacheKey)
        PipelineLogger.musicBrainzGenresResolved(tags, cached: false)
        return tags
    }

    private func searchArtistID(name: String) async throws -> String {
        guard let base = Constants.MusicBrainz.apiBaseURL else {
            throw MusicBrainzError.networkFailed("Invalid base URL")
        }
        var components = URLComponents(url: base.appendingPathComponent("artist"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "query", value: "artist:\"\(name)\""),
            URLQueryItem(name: "fmt", value: "json"),
            URLQueryItem(name: "limit", value: "1")
        ]
        guard let url = components?.url else {
            throw MusicBrainzError.networkFailed("Invalid search URL")
        }
        let data = try await performGET(url: url)
        let response = try JSONDecoder().decode(MusicBrainzArtistSearchResponse.self, from: data)
        guard let artistID = response.artists.first?.id else {
            throw MusicBrainzError.artistNotFound
        }
        return artistID
    }

    private func fetchArtistTags(artistID: String) async throws -> [String] {
        guard let base = Constants.MusicBrainz.apiBaseURL else {
            throw MusicBrainzError.networkFailed("Invalid base URL")
        }
        var components = URLComponents(url: base.appendingPathComponent("artist/\(artistID)"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "inc", value: "tags"),
            URLQueryItem(name: "fmt", value: "json")
        ]
        guard let url = components?.url else {
            throw MusicBrainzError.networkFailed("Invalid artist URL")
        }
        let data = try await performGET(url: url)
        let response = try JSONDecoder().decode(MusicBrainzArtistDetailResponse.self, from: data)
        let tags = response.tags
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map(\.name)
        guard !tags.isEmpty else { throw MusicBrainzError.noTagsFound }
        return Array(tags)
    }

    private func performGET(url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue(Constants.MusicBrainz.userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10
        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw MusicBrainzError.invalidResponse(statusCode: -1)
            }
            guard http.statusCode == 200 else {
                throw MusicBrainzError.invalidResponse(statusCode: http.statusCode)
            }
            return data
        } catch let error as MusicBrainzError {
            throw error
        } catch {
            throw MusicBrainzError.networkFailed(error.localizedDescription)
        }
    }
}

private struct MusicBrainzArtistSearchResponse: Decodable {
    struct Artist: Decodable {
        let id: String
    }

    let artists: [Artist]
}

private struct MusicBrainzArtistDetailResponse: Decodable {
    struct Tag: Decodable {
        let name: String
        let count: Int
    }

    let tags: [Tag]
}
