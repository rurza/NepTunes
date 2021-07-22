//
//  LoginViewState.swift
//  
//
//  Created by Adam Różyński on 22/07/2021.
//

import ComposableArchitecture
import LastFm

struct LoginViewState: Equatable {
    var username: String = ""
    var password: String = ""
    var loading: Bool = false
    var isLoggedIn: Bool = false
    var userAvatarData: Data? = nil
    
    var unableToLogin: Bool {
        username.count == 0 || password.count == 0 || loading
    }
}

extension OnboardingState {
    var loginViewState: LoginViewState {
        .init(username: lastFmState.username ?? (lastFmState.loginState?.username ?? ""),
              password: lastFmState.loginState?.password ?? "",
              loading: lastFmState.loginState?.loading ?? false,
              isLoggedIn: lastFmState.userSessionKey != nil,
              userAvatarData: lastFmState.userAvatarData)
    }
}
