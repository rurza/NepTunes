//
//  LastFmState.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import Foundation

public struct LastFmState: Equatable {
    var loginState: LastFmLoginState?
    var userAvatarData: Data? = nil
    
    public init(loginState: LastFmLoginState? = nil,
                userAvatarData: Data? = nil) {
        self.loginState = loginState
        self.userAvatarData = userAvatarData
    }
}

public struct LastFmLoginState: Equatable {
    var username: String?
    var password: String?
}
