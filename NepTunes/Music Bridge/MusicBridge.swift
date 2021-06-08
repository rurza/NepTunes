//
//  MusicBridge.swift
//  NepTunes
//
//  Created by Adam Różyński on 10/05/2021.
//

import AppleScriptObjC
import Cocoa

// dynamic cast, that's why the alias is set to NSObject
@objc(NSObject) protocol MusicBridge {
    
    var isRunning: NSNumber { get }
    var playerState: NSNumber { get }
    var soundVolume: NSNumber { get }
    var trackDuration: NSNumber { get }
    var trackLoved: NSNumber { get }
    var trackArtwork: NSImage { get }
    var trackInfo: NSDictionary { get }
    var trackFullInfo: NSDictionary { get }
    
    
    func playPause()
    func setSoundVolume(_ volume: NSNumber)
    func nextTrack()
    func backTrack()
}

extension MusicBridge {
    var isRunning: Bool { self.isRunning.boolValue }
    
    var volume: Int {
        set {
            setSoundVolume(NSNumber(integerLiteral: newValue))
        }
        get {
            soundVolume.intValue
        }
    }
    
    var state: MusicPlayerState { MusicPlayerState(rawValue: self.playerState.intValue) }
    
    var currentTrack: MusicTrackInfo? {
        guard let duration = trackInfo["trackDuration"] as? Double else { return nil }
        return MusicTrackInfo(title: trackInfo["trackName"] as! String,
                              artist: trackInfo["trackArtist"] as! String,
                              duration: duration,
                              album: trackInfo["trackAlbum"] as? String,
                              albumArtist: trackInfo["albumArtist"] as? String,
                              artworkImageData: (trackInfo["trackArtworkData"] as? NSAppleEventDescriptor)?.data,
                              dateAdded: trackInfo["dateAdded"] as? Date)
    }
}

enum MusicPlayerState { // Music' 'player state' property
    case unknown // extra case e.g. Music is not running
    case stopped
    case playing
    case paused
    case fastForwarding
    case rewinding
    
    init(rawValue: Int) {
        switch rawValue {
        case 1:
            self = .stopped
        case 2:
            self = .playing
        case 3:
            self = .paused
        case 4:
            self = .fastForwarding
        case 5:
            self = .rewinding
        default:
            self = .unknown
        }
    }
    
}

