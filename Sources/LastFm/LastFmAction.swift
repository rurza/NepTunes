//
//  LastFmAction.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import Foundation
import LastFmKit
import Shared

public enum LastFmAction: Equatable {
    case trackAction(LastFmTrackAction)
    case userAction(LastFmUserAction)
}

public enum LastFmTrackAction: Equatable {
    case scrobbleNow(Track)
    case updateNowPlaying(Track)
    case love(Track)
    case unlove(Track)
}


public enum LastFmUserAction: Equatable {

    case signIn
    case signOut
    case signUp
    case userLoginResponse(Result<LastFmSession, Error>)
    case getUserAvatar
    case userAvatarResponse(Result<Data, Error>)
    case setUsername(String)
    case setPassword(String)
    case dismissAlert
    
    public static func == (lhs: LastFmUserAction, rhs: LastFmUserAction) -> Bool {
        switch (lhs, rhs) {
        case let (.userLoginResponse(lhsResult), .userLoginResponse(rhsResult)):
            switch (lhsResult, rhsResult) {
            case let (.success(lhsSession), .success(rhsSession)):
                return lhsSession == rhsSession
            case (.failure, .failure):
                return true
            default:
                return false
            }
        case let (.userAvatarResponse(lhsResult), .userAvatarResponse(rhsResult)):
            switch (lhsResult, rhsResult) {
            case let (.success(lhsAvatarData), .success(rhsAvatarData)):
                return lhsAvatarData == rhsAvatarData
            case (.failure, .failure):
                return true
            default:
                return false
            }
        case let (.setUsername(lhsUsername), .setUsername(rhsUsername)):
            return lhsUsername == rhsUsername
        case let (.setPassword(lhsPassword), .setPassword(rhsPassword)):
            return lhsPassword == rhsPassword
        case (.signOut, .signOut):
            return true
        case (.signUp, .signUp):
            return true
        case (.signIn, .signIn):
            return true
        case (.getUserAvatar, .getUserAvatar):
            return true
        case (.dismissAlert, .dismissAlert):
            return true
        default:
            return false
        }
    }
}
