//
//  CandidateDict.swift
//  ToneBoard
//
//  Created by Kevin Bell on 12/7/21.
//

import Foundation

protocol CandidateDict {
    func candidates(_ syllables: [String]) -> [String]
}

struct SimpleCandidateDict: CandidateDict {
    let readingCandidates = [
        "fei1": ["非"],
        "fei1 chang2": ["非常"],
        "wo3": ["我"],
        "bu4": ["不", "部", "步", "布", "簿", "埔", "歩", "怖", "埠", "埗", "鈈", "蔀", "吥", "鈽", "佈", "歨", "餔", "篰", "悑", "捗", "瓿"]
    ]
    
    func candidates(_ syllables: [String]) -> [String] {
        return readingCandidates[syllables.joined(separator: " ")] ?? []
    }
}

struct JsonCandidateDict: CandidateDict {
    let readingCandidates: [String: [String]]
    
    init() {
        let bundlePath = Bundle.main.path(forResource: "dict", ofType: "json")
        let jsonData = try! String(contentsOfFile: bundlePath!).data(using: .utf8)
        readingCandidates = try! JSONSerialization.jsonObject(with: jsonData!, options: []) as! [String: [String]]
    }
    
    func candidates(_ syllables: [String]) -> [String] {
        return readingCandidates[syllables.joined(separator: " ")] ?? []
    }
}


class LazyCandidateDict: CandidateDict {

    // TODO: Likely need to make sure this isn't queried by anything while being updated from init
    var dict: CandidateDict?
    
    init() {
        Task {
            dict = JsonCandidateDict()
        }
    }
    
    func candidates(_ syllables: [String]) -> [String] {
        dict?.candidates(syllables) ?? []
    }
}
