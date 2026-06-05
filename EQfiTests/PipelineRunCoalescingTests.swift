//
//  PipelineRunCoalescingTests.swift
//  EQfiTests
//
//  Created by Ahsan Minhas on 06/06/2026.
//

import XCTest
@testable import EQfi

final class PipelineRunCoalescingTests: XCTestCase {
    func testShouldAwaitExistingRunWhenSameTrackAndNotForced() {
        XCTAssertTrue(
            PipelineRunCoalescing.shouldAwaitExistingRun(
                force: false,
                inFlightKey: "bruno mars|locked out of heaven",
                newKey: "bruno mars|locked out of heaven"
            )
        )
    }

    func testShouldNotAwaitExistingRunWhenTrackChanges() {
        XCTAssertFalse(
            PipelineRunCoalescing.shouldAwaitExistingRun(
                force: false,
                inFlightKey: "bruno mars|locked out of heaven",
                newKey: "bruno mars|treasure"
            )
        )
    }

    func testShouldNotAwaitExistingRunWhenForcedRetry() {
        XCTAssertFalse(
            PipelineRunCoalescing.shouldAwaitExistingRun(
                force: true,
                inFlightKey: "bruno mars|locked out of heaven",
                newKey: "bruno mars|locked out of heaven"
            )
        )
    }
}
