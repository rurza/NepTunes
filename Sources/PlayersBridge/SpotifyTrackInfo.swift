//
//  SpotifyTrackInfo.swift
//  NepTunes
//
//  Created by Adam Różyński on 06/07/2021.
//

import Foundation

struct SpotifyTrackInfo {
    let title: String
    let artist: String
    let duration: Double
    let artworkURL: URL?
    var album: String?
    var albumArtist: String?
}
