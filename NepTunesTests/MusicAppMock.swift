//
//  MusicAppMock.swift
//  NepTunesTests
//
//  Created by Adam Różyński on 26/06/2021.
//

@testable import NepTunes

struct MusicAppMock: Player {
    
    var type: PlayerType = .musicApp
    
    var currentTrack: Track? = nil
    
    var volume: Int = 100
    
    var state: MusicPlayerState = .stopped
    
    func playPause() {
        
    }
    
    func nextTrack() {
        
    }
    
    func backTrack() {
        
    }
    
    
}
