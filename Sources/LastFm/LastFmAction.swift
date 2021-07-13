//
//  LastFmAction.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import Foundation
import LastFmKit

public enum LastFmAction: Equatable {
    case trackAction(LastFmTrackAction)
    case userAction(LastFmUserAction)
}

public enum LastFmTrackAction: Equatable {
    case scrobbleNow(title: String, artist: String, albumArtist: String?, album: String?)
    case updateNowPlaying(title: String, artist: String, albumArtist: String?, album: String?)
    case love(title: String, artist: String)
    case unlove(title: String, artist: String)
}


public enum LastFmUserAction: Equatable {
    case getUserAvatar(username: String)
    case logIn(username: String, password: String)
    case userLoginResponse(Result<LastFmSession, Error>)
    case setUsername(String)
    case password(String)
    case logOut
    
    public static func == (lhs: LastFmUserAction, rhs: LastFmUserAction) -> Bool {
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
        case let (.setUsername(lhsUsername), .setUsername(rhsUsername)):
            return lhsUsername == rhsUsername
        case let (.password(lhsPassword), .password(rhsPassword)):
            return lhsPassword == rhsPassword
        case (.logOut, .logOut):
            return true
        default:
            return false
        }
    }
}
