//
//  GenreCacheProtocol.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Caches Spotify genre lookups in memory and persistent storage.
protocol GenreCacheProtocol: Sendable {
    /// Returns cached genres for a track key, if present.
    func genre(forKey key: String) -> [String]?

    /// Stores genres for a track key.
    func store(genres: [String], forKey key: String)

    /// Removes a single cached entry.
    func remove(forKey key: String)

    /// Clears all cached genre entries.
    func clearAll()
}
