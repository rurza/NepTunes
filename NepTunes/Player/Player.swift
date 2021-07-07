//
//  Player.swift
//  NepTunes
//
//  Created by Adam Różyński on 16/05/2021.
//

import Cocoa

protocol Player {
    var type: PlayerType { get }
    
    /// set for the test purposes
    var currentTrack: Track? { get }
    var volume: Int { get set }
    var state: PlayerPlaybackState { get }
    func playPause()
    func nextTrack()
    func backTrack()
    
    var isRunning: Bool { get }
}

enum PlayerType: String, CaseIterable, Equatable {
    case spotify = "com.spotify.client"
    case musicApp = "com.apple.Music"
}


extension PlayerType {
    init?(runningApplication: NSRunningApplication?) {
        guard let bundleIdentifier = runningApplication?.bundleIdentifier else { return nil }
        self.init(rawValue: bundleIdentifier)
    }
}

enum PlayerPlaybackState {
    case unknown
    case stopped
    case playing
    case paused
}
