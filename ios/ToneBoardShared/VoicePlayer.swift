//
//  VoicePlayer.swift
//  ToneBoard
//
//  Created by Kevin Bell on 5/1/22.
//

import Foundation
import SQLite
import AVFoundation


class VoicePlayer {
    
    let db: Connection
    let hashData = Table("hash_data")
    let hash = Expression<String>("hash")
    let data = Expression<Blob>("data")
    
    var audioPlayer: AVAudioPlayer?
    
    init() {
        let path = Bundle.main.path(forResource: "audio", ofType: "sqlite3")!
        db = try! Connection(path, readonly: true)
    }
    
    func getData(_ audioHash: String) -> Data? {
        // TODO: Handle DB file not existing if on-demand resource
        if let result = try! db.pluck(hashData.filter(hash == audioHash)) {
            return Data.fromDatatypeValue(result[data])
        } else {
            return nil
        }
    }
    
    func play(_ audioHash: String) {
        if let data = getData(audioHash) {
            // TODO: Handle errors
            audioPlayer = try! AVAudioPlayer(data: data)
            audioPlayer!.play()
        }
    }
}
