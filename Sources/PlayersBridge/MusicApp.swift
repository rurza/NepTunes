//
//  MusicApp.swift
//  NepTunes
//
//  Created by Adam Różyński on 10/05/2021.
//

import Foundation
import AppleScriptObjC
import Shared

public class MusicApp: Player {
    
    public var isRunning: Bool { bridge.isRunning.boolValue }
    
    public var type: PlayerType = .musicApp
    public var currentTrack: Track? {
        // extremely important to check if the app is running, otherwise it'll launch it
        guard isRunning else {
            return nil
        }
        if let bridgeTrack = bridge.currentTrack {
            return Track(title: bridgeTrack.title,
                         artist: bridgeTrack.artist,
                         album: bridgeTrack.album,
                         albumArtist: bridgeTrack.albumArtist,
                         artworkData: bridgeTrack.artworkImageData,
                         artworkURL: nil,
                         duration: bridgeTrack.duration)
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
    
    private lazy var bridge: MusicBridge = {
        // AppleScriptObjC setup
        Bundle.main.loadAppleScriptObjectiveCScripts()
        // create an instance of MusicBridge script object for Swift code to use
        
        let musicAppleScriptClass: AnyClass = NSClassFromString("MusicScript")!
        
        let bridge = musicAppleScriptClass.alloc() as! MusicBridge
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
        bridge.backTrack()
    }
    
}
