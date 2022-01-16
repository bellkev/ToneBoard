//
//  CandidateDict.swift
//  ToneBoard
//
//  Created by Kevin Bell on 12/7/21.
//

import Foundation
import SQLite

struct Candidate: Codable, Equatable {
    let char: String
    var rareTone = false
    private enum CodingKeys : String, CodingKey {
            case char, rareTone = "rare_tone"
    }
}

protocol CandidateDict {
    func candidates(_ syllables: [String]) -> [Candidate]
}

struct SimpleCandidateDict: CandidateDict {
    let readingCandidates = [
        "fei1": ["非"],
        "fei1 chang2": ["非常"],
        "wo3": ["我"],
        "bu4": ["不", "部", "步", "布", "簿", "埔", "歩", "怖", "埠", "埗", "鈈", "蔀", "吥", "鈽", "佈", "歨", "餔", "篰", "悑", "捗", "瓿"]
    ]
    
    func candidates(_ syllables: [String]) -> [Candidate] {
        let stringCandidates = readingCandidates[syllables.joined(separator: " ")] ?? []
        return stringCandidates.map { Candidate(char: $0)}
    }
}


class SQLiteCandidateDict: CandidateDict {
    
    let db: Connection
    let readingChar = Table("reading_char")
    let reading = Expression<String>("reading")
    let frequency = Expression<Double>("frequency")

    
    init() {
        let path = Bundle.main.path(forResource: "dict", ofType: "sqlite3")!
        db = try! Connection(path, readonly: true)
    }
    
    func candidates(_ syllables: [String]) -> [Candidate] {
        
        let result = try! db.prepareRowIterator(readingChar.filter(reading == syllables.joined(separator: " ")).order(frequency.desc))
        return try! result.map {try! $0.decode()}
    }
}
