//
//  SpotifyMock.swift
//  NepTunesTests
//
//  Created by Adam Różyński on 12/07/2021.
//

import Foundation
@testable import NepTunes

struct SpotifyMock: Player {
    
    var type: PlayerType = .spotify
    
    var currentTrack: Track? = nil
    
    var volume: Int = 100
    
    var state: PlayerPlaybackState = .stopped
    
    func playPause() { }
    
    func nextTrack() { }
    
    func backTrack() { }
    
    var isRunning: Bool { true }
    
}
