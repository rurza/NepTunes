//
//  LastFmState.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import Foundation

public struct LastFmState: Equatable {
    var loginState: LastFmLoginState?
    
    public init(loginState: LastFmLoginState? = nil) {
        self.loginState = loginState
    }
}

public struct LastFmLoginState: Equatable {
    var username: String?
    var password: String?
}
