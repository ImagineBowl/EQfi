//
//  OllamaModelPickerTests.swift
//  EQfiTests
//
//  Created by Ahsan Minhas on 06/06/2026.
//

import XCTest
@testable import EQfi

final class OllamaModelPickerTests: XCTestCase {
    func testSelectBestPrefersLoadedLlama32OverLlama31() {
        let names = ["llama3.1:latest", "llama3.2:latest"]
        XCTAssertEqual(OllamaModelPicker.selectBest(from: names), "llama3.2:latest")
    }

    func testSelectBestUsesLoadedLlama31WhenOnlyLlamaInstalled() {
        let names = ["llama3.1:latest"]
        XCTAssertEqual(OllamaModelPicker.selectBest(from: names), "llama3.1:latest")
    }

    func testSelectBestPrefersLlamaOverNonLlamaModels() {
        let names = ["mistral:latest", "llama3.2:latest"]
        XCTAssertEqual(OllamaModelPicker.selectBest(from: names), "llama3.2:latest")
    }

    func testSelectBestFallsBackToFirstModelWhenNoLlamaInstalled() {
        let names = ["mistral:latest", "phi3:latest"]
        XCTAssertEqual(OllamaModelPicker.selectBest(from: names), "mistral:latest")
    }

    func testSelectBestReturnsNilForEmptyList() {
        XCTAssertNil(OllamaModelPicker.selectBest(from: []))
    }
}
