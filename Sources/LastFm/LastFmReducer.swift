//
//  LastFmReducer.swift
//  NepTunes
//
//  Created by Adam Różyński on 14/05/2021.
//

import ComposableArchitecture
import Shared

let lastFmUserReducer = Reducer<LastFmState, LastFmUserAction, SystemEnvironment<LastFmEnvironment>> { state, action, environment in
    switch action {
    case .logIn:
        guard let username = state.loginState?.username,
              let password = state.loginState?.password else { return .none }
        return environment.lastFmClient
            .logInUser(username, password)
            .retry(2, delay: 2, scheduler: environment.mainQueue)
            .catchToEffect()
            .map(LastFmUserAction.userLoginResponse)
    case let .userLoginResponse(response):
        switch response {
        case let .success(session):
            environment.settings.session = session.key
            environment.settings.username = session.name
            state.loginState = nil
        case let .failure(error):
            
            return .none
        }

        return .none
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
    case .logOut:
        environment.settings.session = nil
        environment.settings.username = nil
        state.loginState = nil
        state.userAvatarData = nil
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
    }
}

let lastFmTrackReducer = Reducer<LastFmState, LastFmTrackAction, SystemEnvironment<LastFmEnvironment>> { state, action, environment in
    
    switch action {
    case .scrobbleNow(title: let title, artist: let artist, albumArtist: let albumArtist, album: let album):
        return .none
    case .updateNowPlaying(title: let title, artist: let artist, albumArtist: let albumArtist, album: let album):
        return .none
    case .love(title: let title, artist: let artist):
        return .none
    case .unlove(title: let title, artist: let artist):
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


