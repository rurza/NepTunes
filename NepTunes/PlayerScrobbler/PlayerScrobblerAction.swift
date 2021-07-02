//
//  PlayerScrobblerAction.swift
//  NepTunes
//
//  Created by Adam Różyński on 01/07/2021.
//

import Foundation

enum PlayerScrobblerAction: Equatable {
    case timerAction(LastFmTimerAction)
    case playerInfo(Track)
    case newTrack(Track)
    case trackBasicInfoAvailable(Track)
    case scrobbleNow(title: String, artist: String, albumArtist: String?, album: String?)
    case updateNowPlaying(title: String, artist: String, albumArtist: String?, album: String?)
}
