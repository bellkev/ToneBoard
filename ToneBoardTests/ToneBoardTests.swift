//
//  ToneBoardTests.swift
//  ToneBoardTests
//
//  Created by Kevin Bell on 12/7/21.
//

import XCTest
@testable import ToneBoard

class ToneBoardTests: XCTestCase {

    func testExample() throws {
        let input = ToneBoardInput("fei1chang2abc")
        assert(input.syllables == ["fei1", "chang2"])
        assert(input.remainder == "abc")
    }

}
