//
//  LastFmAction.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import Foundation
import LastFmKit

enum LastFmAction: Equatable {
    case trackAction(LastFmTrackAction)
    case userAction(LastFmUserAction)
}

enum LastFmTrackAction: Equatable {
    case scrobbleNow(title: String, artist: String, albumArtist: String?, album: String?)
    case updateNowPlaying(title: String, artist: String, albumArtist: String?, album: String?)
    case love(title: String, artist: String)
    case unlove(title: String, artist: String)
}


enum LastFmUserAction: Equatable {
    case getUserAvatar(username: String)
    case logIn(username: String, password: String)
    case userLoginResponse(Result<LastFmSession, Error>)
    case logOut
}

extension LastFmUserAction {
    static func == (lhs: LastFmUserAction, rhs: LastFmUserAction) -> Bool {
        switch (lhs, rhs) {
        case let (.userLoginResponse(lhsResult), .userLoginResponse(rhsResult)):
            switch (lhsResult, rhsResult) {
            case let (.success(lhsSession), .success(rhsSession)):
                return lhsSession == rhsSession
            default:
                return false
            }
        case let (.logIn(username: lhsUsername, password: lhsPassword), .logIn(username: rhsUsername, password: rhsPassword)):
            return lhsUsername == rhsUsername && lhsPassword == rhsPassword
        case let (.getUserAvatar(username: lhsUsername), .getUserAvatar(username: rhsUsername)):
            return lhsUsername == rhsUsername
        default:
            return false
        }
    }
}

