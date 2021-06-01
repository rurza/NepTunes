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
    var coverData: Data
}

