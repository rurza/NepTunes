//
//  MusicAppMock.swift
//  NepTunesTests
//
//  Created by Adam Różyński on 26/06/2021.
//


// this has to be a reference type, so we can simulate the environment change
class MusicAppMock: Player {
    
    var state: PlayerPlaybackState = .stopped
    
    var isRunning: Bool { true }
    
    var type: PlayerType = .musicApp
    
    var currentTrack: Track? = nil
    
    var volume: Int = 100
    
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
