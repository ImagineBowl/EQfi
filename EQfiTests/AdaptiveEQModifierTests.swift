//
//  AdaptiveEQModifierTests.swift
//  EQfiTests
//
//  Created by Ahsan Minhas on 05/06/2026.
//

import XCTest
@testable import EQfi

final class AdaptiveEQModifierTests: XCTestCase {
    private let modifier = AdaptiveEQModifier()
    private let base = EQProfileBridge.toEightBand(.flat())

    func testWarmNeoSoulBassDoesNotTriggerCut() {
        let features = makeFeatures(bassEnergy: 0.58, trebleEnergy: 0.09)
        let gains = modifier.modifiedBands(base: base, features: features)
        XCTAssertEqual(gains, base.bands.map(\.gain))
    }

    func testVeryHighBassTriggersSmallCut() {
        let features = makeFeatures(bassEnergy: 0.8, trebleEnergy: 0.1)
        let gains = modifier.modifiedBands(base: base, features: features)
        XCTAssertLessThan(gains[1], 0)
        XCTAssertLessThan(gains[2], 0)
        XCTAssertGreaterThan(gains[1], -1.5)
    }

    func testLowTrebleTriggersSmallBoost() {
        let features = makeFeatures(bassEnergy: 0.3, trebleEnergy: 0.02)
        let gains = modifier.modifiedBands(base: base, features: features)
        XCTAssertGreaterThan(gains[6], 0)
        XCTAssertGreaterThan(gains[7], 0)
        XCTAssertLessThan(gains[7], 1.5)
    }

    func testBoostScalesDownWhenBaseBandAlreadyHot() {
        var hotBands = base.bands
        hotBands[7].gain = 11.5
        let hotBase = EQManualProfile(bands: hotBands, masterGain: 0, presetName: "Hot")
        let features = makeFeatures(bassEnergy: 0.2, trebleEnergy: 0.02)
        let gains = modifier.modifiedBands(base: hotBase, features: features)
        XCTAssertLessThan(gains[7] - hotBands[7].gain, 0.35)
    }

    func testPerBandDeltaStaysWithinStackCap() {
        let features = makeFeatures(
            bassEnergy: 0.05,
            trebleEnergy: 0.02,
            harshness: 0.6,
            centroid: 700
        )
        let gains = modifier.modifiedBands(base: base, features: features)
        for (applied, original) in zip(gains, base.bands.map(\.gain)) {
            XCTAssertLessThanOrEqual(abs(applied - original), Constants.AdaptiveEQ.maxStackedDeltaDB + 0.001)
        }
    }

    private func makeFeatures(
        bassEnergy: Float,
        trebleEnergy: Float,
        harshness: Float = 0.1,
        centroid: Float = 1_500
    ) -> AudioFeatures {
        AudioFeatures(
            bassEnergy: bassEnergy,
            trebleEnergy: trebleEnergy,
            rmsLoudnessDB: -28,
            spectralCentroidHz: centroid,
            dynamicRangeDB: 8,
            harshness: harshness,
            capturedAt: Date()
        )
    }
}
