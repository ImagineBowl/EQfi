//
//  EQProfileCache.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// In-memory EQ profile cache backed by UserDefaults persistence.
final class EQProfileCache: EQProfileCacheProtocol, @unchecked Sendable {
    private let defaults: UserDefaults
    private let cacheKey: String
    private var memoryCache: [String: CachedEQProfile]
    private let lock = NSLock()

    init(
        defaults: UserDefaults = .standard,
        cacheKey: String = Constants.UserDefaultsKeys.eqProfileCache
    ) {
        self.defaults = defaults
        self.cacheKey = cacheKey
        self.memoryCache = Self.loadFromDefaults(defaults: defaults, cacheKey: cacheKey)
    }

    /// Returns a cached profile entry for the key, if present.
    func profile(forKey key: String) -> CachedEQProfile? {
        lock.lock()
        defer { lock.unlock() }
        return memoryCache[key]
    }

    /// Stores a profile entry for the key.
    func store(_ entry: CachedEQProfile, forKey key: String) {
        lock.lock()
        memoryCache[key] = entry
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

    /// Clears all cached profile entries.
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
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: cacheKey)
    }

    private static func loadFromDefaults(defaults: UserDefaults, cacheKey: String) -> [String: CachedEQProfile] {
        guard let data = defaults.data(forKey: cacheKey),
              let stored = try? JSONDecoder().decode([String: CachedEQProfile].self, from: data) else {
            return [:]
        }
        return stored
    }
}
