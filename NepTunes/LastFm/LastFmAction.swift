//
//  LastFmAction.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import Foundation
import LastFmKit

enum LastFmAction {
    case trackAction(LastFmTrackAction)
    case userAction(LastFmUserAction)
    case timerAction(LastFmTimerAction)
    case trackDidChange
}

enum LastFmTrackAction {
    case scrobbleNow(title: String, artist: String, albumArtist: String?, album: String?)
    case updateNowPlaying(title: String, artist: String, albumArtist: String?, album: String?)
    case love(title: String, artist: String)
    case unlove(title: String, artist: String)
}


enum LastFmUserAction {
    case getUserAvatar(username: String)
    case logIn(username: String, password: String)
    case userLoginResponse(Result<LastFmSession, Error>)
    case setUsername(String)
    case password(String)
    case logOut
}

enum LastFmTimerAction {
    case invalidate
    case start
    case timerTicked
    case toggle
}

