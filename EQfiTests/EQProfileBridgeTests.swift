//
//  EQProfileBridgeTests.swift
//  EQfiTests
//
//  Created by Ahsan Minhas on 05/06/2026.
//

import XCTest
@testable import EQfi

final class EQProfileBridgeTests: XCTestCase {
    func testInterpolatesAdjacentBandsInsteadOfDuplicating() {
        let profile = EQProfile(
            subBass: -2,
            bass: 4,
            midrange: 1,
            presence: 3,
            brilliance: 5,
            presetName: "Test",
            reasoning: nil
        )

        let manual = EQProfileBridge.toEightBand(profile)
        let gains = manual.bands.map(\.gain)

        XCTAssertEqual(gains[0], -2, accuracy: 0.001)
        XCTAssertEqual(gains[1], 0.1, accuracy: 0.001)
        XCTAssertEqual(gains[2], 1.9, accuracy: 0.001)
        XCTAssertEqual(gains[3], 2.95, accuracy: 0.001)
        XCTAssertEqual(gains[4], 1, accuracy: 0.001)
        XCTAssertEqual(gains[5], 2.3, accuracy: 0.001)
        XCTAssertEqual(gains[6], 3.7, accuracy: 0.001)
        XCTAssertEqual(gains[7], 4.3, accuracy: 0.001)
    }

    func testFlatProfileRemainsFlatAcrossEightBands() {
        let manual = EQProfileBridge.toEightBand(.flat())
        XCTAssertTrue(manual.bands.allSatisfy { abs($0.gain) < 0.001 })
    }
}
