//
//  Track.swift
//  NepTunes
//
//  Created by Adam Różyński on 16/05/2021.
//

import Foundation

public struct Track: Equatable {
    
    public let title: String
    public let artist: String
    public var album: String?
    public var albumArtist: String?
    public var artworkData: Data?
    public let artworkURL: URL?
    public var duration: TimeInterval?
    
    public init?(title: String,
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
    
    public init?(userInfo: [AnyHashable : Any]?) {
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
    
    public func isTheSameTrackAs(_ track: Track?) -> Bool {
        self.artist == track?.artist && self.title == track?.title && self.album == track?.album
    }
}
