//
//  GenreLookupFallbackProtocol.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Secondary genre lookup when Spotify is unavailable.
protocol GenreLookupFallbackProtocol: Sendable {
    /// Looks up genre tags for the given track.
    func fetchGenre(for track: TrackInfo) async throws -> [String]
}
