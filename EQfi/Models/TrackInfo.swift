//
//  TrackInfo.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Represents the currently playing media item detected from the system.
struct TrackInfo: Codable, Sendable, Equatable, Hashable {
    let title: String
    let artist: String
    let source: TrackSource
    let isPodcast: Bool

    /// Returns a stable cache key combining title and artist for genre lookups.
    var cacheKey: String {
        "\(artist)|\(title)".lowercased()
    }

    /// Returns a cache key for EQ profiles scoped to an output device.
    func eqProfileCacheKey(device: AudioDevice) -> String {
        "\(cacheKey)|\(device.rawValue)"
    }

    /// Returns the primary artist name when multiple artists are listed.
    var primaryArtistName: String {
        artist
            .components(separatedBy: CharacterSet(charactersIn: ",&;"))
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? artist
    }
}
