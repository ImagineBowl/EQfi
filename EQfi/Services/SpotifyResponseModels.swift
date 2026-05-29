//
//  SpotifyResponseModels.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// OAuth token response from Spotify accounts API.
struct SpotifyTokenResponse: Decodable, Sendable {
    let accessToken: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
    }
}

/// Top-level search response wrapper.
struct SpotifySearchResponse: Decodable, Sendable {
    let tracks: SpotifyTrackList
}

struct SpotifyTrackList: Decodable, Sendable {
    let items: [SpotifyTrackItem]
}

struct SpotifyTrackItem: Decodable, Sendable {
    let artists: [SpotifyArtistRef]
}

struct SpotifyArtistRef: Decodable, Sendable {
    let id: String
}

/// Artist detail response containing genres.
struct SpotifyArtistResponse: Decodable, Sendable {
    let genres: [String]
}

/// Artist search response wrapper.
struct SpotifyArtistSearchResponse: Decodable, Sendable {
    let artists: SpotifyArtistList
}

struct SpotifyArtistList: Decodable, Sendable {
    let items: [SpotifyArtistRef]
}
