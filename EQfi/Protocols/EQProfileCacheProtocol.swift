//
//  EQProfileCacheProtocol.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Caches generated EQ profiles per track and output device.
protocol EQProfileCacheProtocol: Sendable {
    /// Returns a cached profile entry for the key, if present.
    func profile(forKey key: String) -> CachedEQProfile?

    /// Stores a profile entry for the key.
    func store(_ entry: CachedEQProfile, forKey key: String)

    /// Removes a single cached entry.
    func remove(forKey key: String)

    /// Clears all cached profile entries.
    func clearAll()
}
