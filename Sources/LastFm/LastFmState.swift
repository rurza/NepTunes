//
//  LastFmState.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import Foundation

public struct LastFmState: Equatable {
    public var loginState: LastFmLoginState?
    public var userAvatarData: Data? = nil
    
    public init(loginState: LastFmLoginState? = nil,
                userAvatarData: Data? = nil) {
        self.loginState = loginState
        self.userAvatarData = userAvatarData
    }
}

public struct LastFmLoginState: Equatable {
    public var username: String?
    public var password: String?
}
