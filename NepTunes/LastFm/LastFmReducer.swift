//
//  LastFmReducer.swift
//  NepTunes
//
//  Created by Adam Różyński on 14/05/2021.
//

import ComposableArchitecture

let lastFmUserReducer = Reducer<LastFmState, LastFmUserAction, LastFmEnvironment> { state, action, environment in
    switch action {
    case let .logIn(username: username, password: password):
        return environment.lastFmClient
            .logInUser(username, password: password)
            .catchToEffect()
            .map(LastFmUserAction.userLoginResponse)
    case let .userLoginResponse(.success(session)):
        state.session = session.key
        state.username = session.name
        return .none
    case let .userLoginResponse(.failure(error)):
        #warning("handle")
        ()
        return .none
    case .getUserAvatar(username: let username):
        return .none
    case .logOut:
        state.session = nil
        state.username = nil
        return .none
    }
}

let lastFmTrackReducer = Reducer<LastFmState, LastFmTrackAction, LastFmEnvironment> { state, action, environment in
    return .none
}

let lastFmReducer = Reducer<LastFmState, LastFmAction, LastFmEnvironment> { state, action, environment in
    switch action {
    case let .trackAction(trackAction):
        return lastFmTrackReducer.run(&state, trackAction, environment).map { .trackAction($0) }
    case let .userAction(userAction):
        return lastFmUserReducer.run(&state, userAction, environment).map { .userAction($0) }
    }
}


