//
//  LastFmReducer.swift
//  NepTunes
//
//  Created by Adam Różyński on 14/05/2021.
//

import ComposableArchitecture
import Shared
import LastFmKit
import SwiftUI

public let lastFmUserReducer = Reducer<LastFmState, LastFmUserAction, SystemEnvironment<LastFmEnvironment>> { state, action, environment in
    switch action {
    case .signIn:
        guard let username = state.loginState?.username,
              let password = state.loginState?.password else { return .none }
        state.loginState?.loading = true
        return environment.lastFmClient
            .logInUser(username, password)
            .retry(3, delay: 2, scheduler: environment.mainQueue, condition: { error in
                error is URLError
            })
            .catchToEffect()
            .map(LastFmUserAction.userLoginResponse)
    case let .userLoginResponse(response):
        state.loginState?.loading = false
        switch response {
        case let .success(session):
            environment.settings.session = session.key
            environment.settings.username = session.name
            state.userSessionKey = session.key
            state.loginState = nil
            state.username = session.name
            return Effect(value: .getUserAvatar)
        case let .failure(error):
            let message: String
            if let error = error as? LastFmError {
                message = error.message
            } else {
                message = error.localizedDescription
            }
            state.loginState?.password = nil
            state.loginState?.alert = AlertState(title: TextState("Sign in error"),
                                                 message: TextState(message),
                                                 dismissButton: .cancel(TextState("OK")))
            return .none
        }

    case .getUserAvatar:
        guard let username = environment.settings.username else { return .none }
        return environment.lastFmClient
            .getAvatar(username)
            .retry(2, delay: 2, scheduler: environment.mainQueue)
            .catchToEffect()
            .map(LastFmUserAction.userAvatarResponse)
    case let .userAvatarResponse(response):
        switch response {
        case let .success(data):
            state.userAvatarData = data
            return .none
        case let .failure(error):
            return .none
        }
    case .signOut:
        environment.settings.session = nil
        environment.settings.username = nil
        state.loginState = nil
        state.userAvatarData = nil
        state.username = nil
        state.userSessionKey = nil
        return .none
    case let .setUsername(username):
        if state.loginState != nil {
            state.loginState?.username = username
        } else {
            state.loginState = LastFmLoginState(username: username, password: nil)
        }
        return .none
    case let .setPassword(password):
        if state.loginState != nil {
            state.loginState?.password = password
        } else {
            state.loginState = LastFmLoginState(username: nil, password: password)
        }
        return .none
    case .signUp:
        return environment
            .signUp(URL(string: "https://www.last.fm/join")!)
            .fireAndForget()
    case .dismissAlert:
        state.loginState?.alert = nil
        return .none
    }
}

let lastFmTrackReducer = Reducer<LastFmState, LastFmTrackAction, SystemEnvironment<LastFmEnvironment>> { state, action, environment in
    
    guard let sessionKey = environment.settings.session else { return .none }
    switch action {
    case .scrobbleNow(let track):
        return environment.scrobblerClient.scrobbleTrack(track, sessionKey, environment.date()).fireAndForget()
    case .updateNowPlaying(let track):
        return environment.scrobblerClient.updateNowPlayingTrack(track, sessionKey).fireAndForget()
    case .love(let track):
        return .none
    case .unlove(let track):
        return .none
    }
}
.debugActions("lastFmTrackReducer")



public let lastFmReducer = Reducer<LastFmState, LastFmAction, SystemEnvironment<LastFmEnvironment>>.combine(
    Reducer { state, action, environment in
        switch action {
        case let .trackAction(trackAction):
            return lastFmTrackReducer.run(&state, trackAction, environment).map { .trackAction($0) }
        case let .userAction(userAction):
            return lastFmUserReducer.run(&state, userAction, environment).map { .userAction($0) }
        }
    }
)


