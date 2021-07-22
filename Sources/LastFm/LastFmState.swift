//
//  LastFmState.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import Foundation
import ComposableArchitecture

public struct LastFmState: Equatable {
    public var loginState: LastFmLoginState?
    public var userAvatarData: Data? = nil
    public var userSessionKey: String? = nil
    public var username: String? = nil
    
    public init(loginState: LastFmLoginState? = nil,
                userAvatarData: Data? = nil,
                userSessionKey: String? = nil,
                username: String? = nil) {
        self.loginState = loginState
        self.userAvatarData = userAvatarData
        self.userSessionKey = userSessionKey
        self.username = username
    }
}

public struct LastFmLoginState: Equatable {
    
    public var username: String?
    public var password: String?
    public var loading = false
    public var alert: AlertState<LastFmUserAction>? = nil
    
    public init(username: String? = nil,
                password: String? = nil,
                loading: Bool = false,
                alert: AlertState<LastFmUserAction>? = nil) {
        self.username = username
        self.password = password
        self.loading = loading
        self.alert = alert
    }
}
