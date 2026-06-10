//
//  PrimaryGenreLookupProtocol.swift
//  EQfi
//
//  Created by Ahsan Minhas on 06/06/2026.
//

import Foundation

/// Fetches artist genres from the hosted genre proxy API.
protocol PrimaryGenreLookupProtocol: Sendable {
    /// Looks up genres for the given track via the genre proxy.
    func fetchGenre(for track: TrackInfo) async throws -> [String]
}
