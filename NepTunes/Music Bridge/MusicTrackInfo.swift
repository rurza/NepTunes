//
//  MusicTrackInfo.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import Foundation

struct MusicTrackInfo {
    let title: String
    let artist: String
    let duration: Double
    var album: String?
    var albumArtist: String?
    var artworkImageData: Data?
    var dateAdded: Date?
//    var trackURL: URL?
}
