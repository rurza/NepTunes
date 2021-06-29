//
//  Track.swift
//  NepTunes
//
//  Created by Adam Różyński on 16/05/2021.
//

import Foundation

struct Track: Equatable {
    
    let title: String
    let artist: String
    var album: String?
    var albumArtist: String?
    var artworkData: Data?
    var duration: TimeInterval?
    
    init(title: String, artist: String, album: String? = nil, albumArtist: String? = nil, artworkData: Data? = nil, duration: TimeInterval?) {
        self.title = title
        self.artist = artist
        self.album = album
        self.albumArtist = albumArtist
        self.artworkData = artworkData
        self.duration = duration
    }
    
    init(userInfo: [AnyHashable : Any]?) {
        if let userInfo = userInfo,
           let title = userInfo["Name"] as? String,
           let artist = userInfo["Artist"] as? String {
            self.title = title
            self.artist = artist
            self.album = userInfo["Album"] as? String
            self.duration = nil
        } else {
            self = .emptyTrack
        }
    }
    
    static let emptyTrack = Track(title: "", artist: "", duration: nil)
    
    func isTheSameTrackAs(_ track: Track?) -> Bool {
        self.artist == track?.artist && self.title == track?.title && self.album == track?.album
    }
}
