//
//  Player.swift
//  NepTunes
//
//  Created by Adam Różyński on 16/05/2021.
//

import Foundation

protocol Player {
    var type: PlayerType { get }
    var currentTrack: Track? { get }
    var volume: Int { set get }
    func playPause()
    func nextTrack()
    func backTrack()
}

enum PlayerType: String, CaseIterable {
    case spotify = "com.spotify.client"
    case musicApp = "com.apple.Music"
}
