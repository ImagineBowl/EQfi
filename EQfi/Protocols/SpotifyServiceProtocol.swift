//
//  SpotifyServiceProtocol.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Fetches artist genres from the Spotify Web API.
protocol SpotifyServiceProtocol: Sendable {
    /// Looks up genres for the given track via search and artist metadata.
    func fetchGenre(for track: TrackInfo) async throws -> [String]

    /// Refreshes the client-credentials token when expired or missing.
    func refreshTokenIfNeeded() async throws
}
