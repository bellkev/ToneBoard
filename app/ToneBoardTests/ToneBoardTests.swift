//
//  ToneBoardTests.swift
//  ToneBoardTests
//
//  Created by Kevin Bell on 12/7/21.
//

import XCTest
@testable import ToneBoard

class ToneBoardTests: XCTestCase {
    
    func randomReading() -> String {
        // Not necessarily always valid syllables and not complete. The goal is just to be able to return a good number of different mostly-valid readings.
        let initials = ["", "p", "m", "f", "d", "t", "n", "l", "g", "k", "j", "q", "x", "zh", "ch", "sh", "r", "z", "c", "s"]
        let finals = ["a", "o", "e", "ai", "ei", "ao", "ou", "an", "en", "ang", "eng", "u", "ua", "uo", "uai", "ui", "uan", "uang"]
        let tones = ["1", "2", "3", "4", "5"]
        let initialIdx = Int.random(in: 0..<initials.count)
        let finalIdx = Int.random(in: 0..<finals.count)
        let toneIdx = Int.random(in: 0..<tones.count)
        return initials[initialIdx] + finals[finalIdx] + tones[toneIdx]
    }

    func testParsing() throws {
        let input = ToneBoardInput("fei1chang2abc")
        assert(input.syllables == ["fei1", "chang2"])
        assert(input.remainder == "abc")
    }
    
    func testDict() throws {
        let dict = SQLiteCandidateDict()
        let candidates = dict.candidates(["fei1", "chang2"])
        assert(candidates == ["非常"])
    }
    
    func testLoadDict() throws {
        let dict = SQLiteCandidateDict()
        let candidates = dict.candidates(["fei1", "chang2"])
        assert(candidates == ["非常"])
    }
    
    func testSubWords() throws {
        let dict = SQLiteCandidateDict()
        let candidates = dict.candidates(["dong1", "xi1", "nan2"])
        assert(candidates == ["东西南"])
    }
    
    func testMultipleResults() throws {
        let dict = SQLiteCandidateDict()
        let candidates = dict.candidates(["wo3"])
        assert(candidates == ["我", "婐"])
    }
    
    func testDictPerf() throws {
        let dict = SQLiteCandidateDict()
        measure{
            for _ in 0...100 {
                let reading = randomReading()
                let _ = dict.candidates([reading])
            }
        }
    }
}
