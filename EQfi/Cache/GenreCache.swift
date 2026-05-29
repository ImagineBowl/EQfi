//
//  GenreCache.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// In-memory genre cache backed by UserDefaults persistence.
final class GenreCache: GenreCacheProtocol, @unchecked Sendable {
    private let defaults: UserDefaults
    private let cacheKey: String
    private var memoryCache: [String: [String]]
    private let lock = NSLock()

    init(
        defaults: UserDefaults = .standard,
        cacheKey: String = Constants.UserDefaultsKeys.genreCache
    ) {
        self.defaults = defaults
        self.cacheKey = cacheKey
        self.memoryCache = Self.loadFromDefaults(defaults: defaults, cacheKey: cacheKey)
    }

    /// Returns cached genres for a track key, if present.
    func genre(forKey key: String) -> [String]? {
        lock.lock()
        defer { lock.unlock() }
        return memoryCache[key]
    }

    /// Stores genres for a track key.
    func store(genres: [String], forKey key: String) {
        lock.lock()
        memoryCache[key] = genres
        lock.unlock()
        persistCache()
    }

    /// Removes a single cached entry.
    func remove(forKey key: String) {
        lock.lock()
        memoryCache.removeValue(forKey: key)
        lock.unlock()
        persistCache()
    }

    /// Clears all cached genre entries.
    func clearAll() {
        lock.lock()
        memoryCache.removeAll()
        lock.unlock()
        persistCache()
    }

    private func persistCache() {
        lock.lock()
        let snapshot = memoryCache
        lock.unlock()
        defaults.set(snapshot, forKey: cacheKey)
    }

    private static func loadFromDefaults(defaults: UserDefaults, cacheKey: String) -> [String: [String]] {
        guard let stored = defaults.dictionary(forKey: cacheKey) as? [String: [String]] else {
            return [:]
        }
        return stored
    }
}
