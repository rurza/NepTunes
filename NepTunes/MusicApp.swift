//
//  MusicApp.swift
//  NepTunes
//
//  Created by Adam Różyński on 10/05/2021.
//

import Foundation
import ScriptingBridge

class MusicApp: Player {
    
    var type: PlayerType = .musicApp
    var currentTrack: Track?
    var volume: Int {
        set {
            bridge.volume = newValue
        }
        get {
            bridge.volume
        }
    }
    
    private lazy var bridge: MusicBridge = {
        // AppleScriptObjC setup
        Bundle.main.loadAppleScriptObjectiveCScripts()
        // create an instance of MusicBridge script object for Swift code to use
        let musicAppleScriptClass: AnyClass = NSClassFromString("MusicScript")!
        let bridge = musicAppleScriptClass.alloc() as! MusicBridge
        return bridge
    }()
    
    func playPause() {
        bridge.playPause()
    }
    
    func nextTrack() {
        bridge.nextTrack()
    }
    
    func backTrack() {
        bridge.backTrack()
    }
    
    
}
