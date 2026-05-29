//
//  KeychainServiceProtocol.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Secure storage for Spotify API credentials.
protocol KeychainServiceProtocol: Sendable {
    /// Saves a string value under the given key.
    func save(_ value: String, forKey key: String) throws

    /// Reads a string value for the given key.
    func read(forKey key: String) throws -> String?

    /// Deletes the value stored under the given key.
    func delete(forKey key: String) throws

    /// Returns whether Spotify credentials have been stored.
    func hasSpotifyCredentials() -> Bool
}
