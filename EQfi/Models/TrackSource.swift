//
//  TrackSource.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import Foundation

/// Identifies the application or service currently playing audio.
enum TrackSource: String, Codable, Sendable, CaseIterable {
    case spotify
    case appleMusic
    case overcast
    case pocketCasts
    case applePodcasts
    case unknown
}
