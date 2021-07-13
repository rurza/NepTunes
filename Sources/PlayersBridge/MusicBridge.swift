//
//  MusicBridge.swift
//  NepTunes
//
//  Created by Adam Różyński on 10/05/2021.
//

import AppleScriptObjC
import Cocoa
import Shared

// dynamic cast, that's why the alias is set to NSObject
@objc(NSObject) protocol MusicBridge {
    
    var isRunning: NSNumber { get }
    var playerState: NSNumber { get }
    var soundVolume: NSNumber { get }
    var trackLoved: NSNumber { get }
    var trackInfo: NSDictionary { get }
    
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
        guard let title = trackInfo["trackName"] as? String, let artist = trackInfo["trackArtist"] as? String else { return nil }
        return MusicTrackInfo(title: title,
                              artist: artist,
                              duration: trackInfo["trackDuration"] as? Double,
                              album: trackInfo["trackAlbum"] as? String,
                              albumArtist: trackInfo["albumArtist"] as? String,
                              artworkImageData: (trackInfo["trackArtworkData"] as? NSAppleEventDescriptor)?.data)
    }
}

enum MusicPlayerState { // Music' 'player state' property
    case unknown // extra case e.g. Music is not running
    case stopped
    case playing
    case paused
    case fastForwarding
    case rewinding
    
    ///stopped, playing, paused, fast forwarding, rewinding}
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
    
    func playerPlaybackState() -> PlayerPlaybackState {
        switch self {
        case .paused:
            return .paused
        case .playing:
            return .playing
        case .stopped:
            return .stopped
        default:
            return .unknown
        }
    }
    
}

