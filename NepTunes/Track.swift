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
    let artworkURL: URL?
    var duration: TimeInterval?
    
    init?(title: String,
         artist: String,
         album: String?,
         albumArtist: String?,
         artworkData: Data?,
         artworkURL: URL?,
         duration: TimeInterval?) {
        guard artist != "" else { return nil }
        self.title = title
        self.artist = artist
        self.album = album
        self.albumArtist = albumArtist
        self.artworkURL = artworkURL
        self.artworkData = artworkData
        self.duration = duration
    }
    
    init?(userInfo: [AnyHashable : Any]?) {
        if let userInfo = userInfo,
           let title = userInfo["Name"] as? String,
           let artist = userInfo["Artist"] as? String,
           artist != "" {
            self.init(title: title,
                      artist: artist,
                      album: userInfo["Album"] as? String,
                      albumArtist: userInfo["AlbumArtist"] as? String,
                      artworkData: nil, artworkURL: nil, duration: nil)
        } else {
            return nil
        }
    }
//
//    static let emptyTrack = Track(title: "",
//                                  artist: "",
//                                  album: nil,
//                                  albumArtist: nil,
//                                  artworkData: nil,
//                                  artworkURL: nil,
//                                  duration: nil)!
    
    func isTheSameTrackAs(_ track: Track?) -> Bool {
        self.artist == track?.artist && self.title == track?.title && self.album == track?.album
    }
}
