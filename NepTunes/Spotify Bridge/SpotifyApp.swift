//
//  SpotifyApp.swift
//  NepTunes
//
//  Created by Adam Różyński on 06/07/2021.
//

import Foundation

class SpotifyApp: Player {
    
    var type: PlayerType = .spotify
    var currentTrack: Track? {
        if let bridgeTrack = bridge.currentTrack {
            return Track(title: bridgeTrack.title,
                         artist: bridgeTrack.artist,
                         album: bridgeTrack.album,
                         albumArtist: bridgeTrack.albumArtist,
                         artworkData: nil,
                         duration: bridgeTrack.duration)
        }
        return nil
    }
    var volume: Int {
        set {
            bridge.volume = newValue
        }
        get {
            bridge.volume
        }
    }
    
    var state: PlayerPlaybackState {
        bridge.state.playerPlaybackState()
    }
    
    private lazy var bridge: SpotifyBridge = {
        // AppleScriptObjC setup
        Bundle.main.loadAppleScriptObjectiveCScripts()
        // create an instance of MusicBridge script object for Swift code to use
        let musicAppleScriptClass: AnyClass = NSClassFromString("SpotifyScript")!
        let bridge = musicAppleScriptClass.alloc() as! SpotifyBridge
        return bridge
    }()
    
    func playPause() {
        bridge.playPause()
    }
    
    func nextTrack() {
        bridge.nextTrack()
    }
    
    func backTrack() {
        bridge.previousTrack()
    }
    
}
