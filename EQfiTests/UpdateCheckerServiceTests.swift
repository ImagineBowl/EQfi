//
//  UpdateCheckerServiceTests.swift
//  EQfiTests
//
//  Created by Ahsan Minhas on 11/06/2026.
//

import XCTest
@testable import EQfi

final class UpdateCheckerServiceTests: XCTestCase {
    func testDismissPreventsSameVersionFromReappearing() async {
        let defaults = UserDefaults(suiteName: "UpdateCheckerServiceTests")!
        defaults.removePersistentDomain(forName: "UpdateCheckerServiceTests")

        let service = UpdateCheckerService(defaults: defaults) { "1.0.0" }
        service.dismiss(version: "1.0.1")

        XCTAssertEqual(
            defaults.string(forKey: Constants.UserDefaultsKeys.dismissedUpdateVersion),
            "1.0.1"
        )
    }
}
