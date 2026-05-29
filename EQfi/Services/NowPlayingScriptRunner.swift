//
//  NowPlayingScriptRunner.swift
//  EQfi
//
//  Created by Ahsan Minhas on 25/05/2026.
//

import AppKit
import Foundation

/// Runs AppleScript snippets to read now-playing metadata from media apps.
struct NowPlayingScriptRunner {
    /// Attempts to read the currently playing track from supported apps.
    func detectTrack() throws -> TrackInfo? {
        let candidates: [(TrackSource, String)] = [
            (.spotify, Self.spotifyScript),
            (.appleMusic, Self.musicScript),
            (.overcast, Self.overcastScript),
            (.pocketCasts, Self.pocketCastsScript),
            (.applePodcasts, Self.podcastsScript)
        ]
        for (source, script) in candidates {
            if let track = try parseResult(run(script), source: source) { return track }
        }
        return nil
    }

    private func run(_ source: String) throws -> String? {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            throw NowPlayingError.scriptFailed("Invalid AppleScript source.")
        }
        let output = script.executeAndReturnError(&error)
        if let error { throw NowPlayingError.scriptFailed(error.description) }
        let string = output.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let string, !string.isEmpty, string != "||" else { return nil }
        return string
    }

    private func parseResult(_ result: String?, source: TrackSource) throws -> TrackInfo? {
        guard let result else { return nil }
        let parts = result.split(separator: "|", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }
        let title = parts[0].trimmingCharacters(in: .whitespaces)
        let artist = parts[1].trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return nil }
        let isPodcast = source.isPodcastSource
        return TrackInfo(title: title, artist: artist, source: source, isPodcast: isPodcast)
    }

    private static let spotifyScript = """
    tell application "Spotify"
        if player state is playing then
            return (name of current track) & "|" & (artist of current track)
        end if
    end tell
    """

    private static let musicScript = """
    tell application "Music"
        if player state is playing then
            return (name of current track) & "|" & (artist of current track)
        end if
    end tell
    """

    private static let overcastScript = """
    tell application "Overcast"
        if playing then
            return (current episode title) & "|" & (current podcast title)
        end if
    end tell
    """

    private static let pocketCastsScript = """
    tell application "Pocket Casts"
        if playing then
            return (name of current track) & "|" & (artist of current track)
        end if
    end tell
    """

    private static let podcastsScript = """
    tell application "Podcasts"
        if player state is playing then
            return (name of current track) & "|" & (artist of current track)
        end if
    end tell
    """
}

private extension TrackSource {
    var isPodcastSource: Bool {
        switch self {
        case .overcast, .pocketCasts, .applePodcasts: return true
        default: return false
        }
    }
}
