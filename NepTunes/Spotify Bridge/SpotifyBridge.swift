//
//  SpotifyBridge.swift
//  NepTunes
//
//  Created by Adam Różyński on 06/07/2021.
//

import Foundation
import AppleScriptObjC

@objc(NSObject) protocol SpotifyBridge {
    
    var isRunning: NSNumber { get }
    var playerState: NSNumber { get }
    var soundVolume: NSNumber { get }
    var trackInfo: NSDictionary { get }
    
    func playPause()
    func setSoundVolume(_ volume: NSNumber)
    func nextTrack()
    func previousTrack()
}

extension SpotifyBridge {
    var isRunning: Bool { self.isRunning.boolValue }
    
    var volume: Int {
        set {
            setSoundVolume(NSNumber(integerLiteral: newValue))
        }
        get {
            soundVolume.intValue
        }
    }
    
    var state: SpotifyState { SpotifyState(rawValue: self.playerState.intValue) }
    
    var currentTrack: SpotifyTrackInfo? {
        // duration in Spotify is in milliseconds
        guard let duration = trackInfo["trackDuration"] as? Double else {
            return nil
        }
        let url: URL?
        if let urlString = trackInfo["trackArtworkURL"] as? String {
            url = URL(string: urlString)
        } else {
            url = nil
        }
        return SpotifyTrackInfo(title: trackInfo["trackName"] as! String,
                                artist: trackInfo["trackArtist"] as! String,
                                duration: duration / 1000,
                                artworkURL: url,
                                album: trackInfo["trackAlbum"] as? String,
                                albumArtist: trackInfo["albumArtist"] as? String)
    }
}

enum SpotifyState { // SpotifyBridge' 'player state' property
    case unknown // extra case e.g. Spotify is not running
    case stopped
    case playing
    case paused
    
    ///stopped, playing, paused
    init(rawValue: Int) {
        switch rawValue {
        case 1:
            self = .stopped
        case 2:
            self = .playing
        case 3:
            self = .paused
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
