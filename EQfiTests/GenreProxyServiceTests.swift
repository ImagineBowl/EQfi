//
//  GenreProxyServiceTests.swift
//  EQfiTests
//
//  Created by Ahsan Minhas on 06/06/2026.
//

import XCTest
@testable import EQfi

final class GenreProxyServiceTests: XCTestCase {
    func testDecodesGenreProxyResponse() throws {
        let json = """
        {"genres":["rock","alternative rock"],"source":"spotify"}
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(GenreProxyResponse.self, from: data)
        XCTAssertEqual(decoded.genres, ["rock", "alternative rock"])
        XCTAssertEqual(decoded.source, "spotify")
    }
}
