//
//  LastFmState.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import Foundation

struct LastFmState {
    /// in the version of the app the key was stored in 'pl.micropixels.neptunes.sessionKey'
    @UserDefault(key: "lastFmSession", defaultValue: nil) var session: String?
    
    /// in the version of the app the key was stored in 'pl.micropixels.neptunes.usernameKey'
    @UserDefault(key: "lastFmUser", defaultValue: nil) var username: String?
    var loginState: LastFmLoginState?
    
    @UserDefault(key: "scrobblePercentage", defaultValue: 50) var scrobblePercentage: UInt
}

struct LastFmLoginState {
    var username: String?
    var password: String?
}

