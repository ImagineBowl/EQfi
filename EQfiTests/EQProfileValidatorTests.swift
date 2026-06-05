//
//  EQProfileValidatorTests.swift
//  EQfiTests
//
//  Created by Ahsan Minhas on 05/06/2026.
//

import XCTest
@testable import EQfi

final class EQProfileValidatorTests: XCTestCase {
    private let validator = EQProfileValidator()

    func testValidJSONProducesProfile() throws {
        let raw = """
        {"sub_bass":1.0,"bass":2.0,"midrange":-1.0,"presence":3.0,"brilliance":0.5,"reasoning":"test"}
        """
        let profile = try validator.validate(rawResponse: raw, presetName: "Rock")
        XCTAssertEqual(profile.subBass, 1.0)
        XCTAssertEqual(profile.bass, 2.0)
        XCTAssertEqual(profile.midrange, -1.0)
        XCTAssertEqual(profile.presence, 3.0)
        XCTAssertEqual(profile.brilliance, 0.5)
        XCTAssertEqual(profile.presetName, "Rock")
        XCTAssertEqual(profile.reasoning, "test")
    }

    func testMarkdownFencesAreStripped() throws {
        let raw = """
        ```json
        {"sub_bass":0,"bass":0,"midrange":0,"presence":0,"brilliance":0}
        ```
        """
        let profile = try validator.validate(rawResponse: raw, presetName: "Flat")
        XCTAssertEqual(profile.presetName, "Flat")
        XCTAssertEqual(profile.bandGains, [0, 0, 0, 0, 0])
    }

    func testGainAboveMaxThrows() {
        let raw = """
        {"sub_bass":13.0,"bass":0,"midrange":0,"presence":0,"brilliance":0}
        """
        XCTAssertThrowsError(try validator.validate(rawResponse: raw, presetName: "Hot")) { error in
            guard case OllamaError.validationFailed = error else {
                XCTFail("Expected validationFailed, got \(error)")
                return
            }
        }
    }

    func testGainBelowMinThrows() {
        let raw = """
        {"sub_bass":0,"bass":0,"midrange":-13.0,"presence":0,"brilliance":0}
        """
        XCTAssertThrowsError(try validator.validate(rawResponse: raw, presetName: "Cold"))
    }

    func testInvalidJSONThrowsDecodingFailed() {
        XCTAssertThrowsError(try validator.validate(rawResponse: "not json", presetName: "Bad")) { error in
            guard case OllamaError.decodingFailed = error else {
                XCTFail("Expected decodingFailed, got \(error)")
                return
            }
        }
    }
}
