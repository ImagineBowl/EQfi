//
//  AppVersionTests.swift
//  EQfiTests
//
//  Created by Ahsan Minhas on 11/06/2026.
//

import XCTest
@testable import EQfi

final class AppVersionTests: XCTestCase {
    func testNormalizedStripsLeadingV() {
        XCTAssertEqual(AppVersion.normalized("v1.0.0"), "1.0.0")
        XCTAssertEqual(AppVersion.normalized("V2.3.4"), "2.3.4")
    }

    func testIsNewerComparesSemverComponents() {
        XCTAssertTrue(AppVersion.isNewer("1.0.1", than: "1.0.0"))
        XCTAssertTrue(AppVersion.isNewer("v1.1.0", than: "1.0.9"))
        XCTAssertFalse(AppVersion.isNewer("1.0.0", than: "1.0.0"))
        XCTAssertFalse(AppVersion.isNewer("1.0.0", than: "2.0.0"))
    }
}
