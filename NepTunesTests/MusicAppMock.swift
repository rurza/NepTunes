//
//  MusicAppMock.swift
//  NepTunesTests
//
//  Created by Adam Różyński on 26/06/2021.
//

@testable import NepTunes

// this has to be a reference type, so we can simulate the environment change
class MusicAppMock: Player {
    
    var type: PlayerType = .musicApp
    
    var currentTrack: Track? = nil
    
    var volume: Int = 100
    
    var state: MusicPlayerState = .stopped
    
    func playPause() {
        switch state {
        case .stopped, .paused:
            state = .playing
        case .playing:
            state = .paused
        default:
            break
        }
    }
    
    func nextTrack() {
        
    }
    
    func backTrack() {
        
    }
    
    
}
