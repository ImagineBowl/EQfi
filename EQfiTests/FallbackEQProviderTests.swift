//
//  FallbackEQProviderTests.swift
//  EQfiTests
//
//  Created by Ahsan Minhas on 05/06/2026.
//

import XCTest
@testable import EQfi

final class FallbackEQProviderTests: XCTestCase {
    func testRockGenreUsesRockFallback() {
        let profile = FallbackEQProvider.profile(for: ["Rock", "Alternative"])
        XCTAssertEqual(profile.presetName, "Rock Fallback")
        XCTAssertGreaterThan(profile.bass, 0)
    }

    func testPodcastGenreUsesPodcastFallback() {
        let profile = FallbackEQProvider.profile(for: ["podcast"])
        XCTAssertEqual(profile.presetName, "Podcast Fallback")
        XCTAssertGreaterThan(profile.midrange, profile.subBass)
    }

    func testElectronicGenreUsesElectronicFallback() {
        let profile = FallbackEQProvider.profile(for: ["edm"])
        XCTAssertEqual(profile.presetName, "Electronic Fallback")
    }

    func testUnknownGenreUsesFlatFallback() {
        let profile = FallbackEQProvider.profile(for: ["unknown"])
        XCTAssertEqual(profile.presetName, "Flat Fallback")
        XCTAssertEqual(profile.bandGains, [0, 0, 0, 0, 0])
    }

    func testSingleGenreStringOverload() {
        let profile = FallbackEQProvider.profile(for: "jazz")
        XCTAssertEqual(profile.presetName, "Jazz Fallback")
    }
}
