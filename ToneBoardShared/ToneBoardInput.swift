//
//  ToneBoardInput.swift
//  ToneBoard
//
//  Created by Kevin Bell on 12/7/21.
//

import Foundation


struct ToneBoardInput: Equatable{
    var syllables = [String]()
    var remainder = ""
    
    init(_ input: String) {
        for char in input {
            if "12345".contains(char) {
                syllables.append(remainder + String(char))
                remainder = ""
            } else {
                remainder.append(char)
            }
        }
    }
    
}
