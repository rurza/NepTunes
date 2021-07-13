//
//  SpotifyApp.swift
//  NepTunes
//
//  Created by Adam Różyński on 06/07/2021.
//

import Foundation
import Shared

public class SpotifyApp: Player {
    
    public var type: PlayerType = .spotify
    
    public var isRunning: Bool { bridge.isRunning.boolValue }
    
    public var currentTrack: Track? {
        // extremely important to check if the app is running, otherwise it'll launch it
        guard isRunning else {
            return nil
        }
        if let bridgeTrack = bridge.currentTrack {
            let track = Track(title: bridgeTrack.title,
                              artist: bridgeTrack.artist,
                              album: bridgeTrack.album,
                              albumArtist: bridgeTrack.albumArtist,
                              artworkData: nil,
                              artworkURL: bridgeTrack.artworkURL,
                              duration: bridgeTrack.duration)
            return track
        }
        return nil
    }
    public var volume: Int {
        set {
            bridge.volume = newValue
        }
        get {
            bridge.volume
        }
    }
    
    public var state: PlayerPlaybackState {
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
    
    public init() { }
    
    public func playPause() {
        bridge.playPause()
    }
    
    public func nextTrack() {
        bridge.nextTrack()
    }
    
    public func backTrack() {
        bridge.previousTrack()
    }
    
}
