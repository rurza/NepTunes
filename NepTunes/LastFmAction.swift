//
//  LastFmAction.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import Foundation

enum LastFmAction {
    case logOut
    case logIn(username: String, password: String)
    case scrobble
    case updateNowPlaying
    case love
    case unlove
    case getAvatar
}
