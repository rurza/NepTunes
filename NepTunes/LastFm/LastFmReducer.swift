//
//  LastFmReducer.swift
//  NepTunes
//
//  Created by Adam Różyński on 14/05/2021.
//

import ComposableArchitecture

let lastFmUserReducer = Reducer<LastFmState, LastFmUserAction, SystemEnvironment<LastFmEnvironment>> { state, action, environment in
    switch action {
    case let .logIn(username: username, password: password):
        return environment.lastFmClient
            .logInUser(username, password: password)
            .catchToEffect()
            .map(LastFmUserAction.userLoginResponse)
    case let .userLoginResponse(.success(session)):
        environment.settings.session = session.key
        environment.settings.username = session.name
        state.loginState = nil
        return .none
    case let .userLoginResponse(.failure(error)):
        #warning("handle")
        ()
        return .none
    case .getUserAvatar(username: let username):
        return .none
    case .logOut:
        environment.settings.session = nil
        environment.settings.username = nil
        state.loginState = nil
        return .none
    case let .setUsername(username):
        if var loginState = state.loginState {
            loginState.username = username
            state.loginState = loginState
        } else {
            state.loginState = LastFmLoginState(username: username, password: nil)
        }
        return .none
    case let .password(password):
        if var loginState = state.loginState {
            loginState.password = password
            state.loginState = loginState
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
.debugActions("👨‍🎤")


let lastFmTimerReducer = Reducer<LastFmTimerState, LastFmTimerAction, SystemEnvironment<LastFmEnvironment>> { state, action, environment in
    
    struct TimerId: Hashable { }
    
    switch action {
    case .invalidate:
        state.isTimerActive = false
        state.secondsElapsed = 0
        return .cancel(id: TimerId())
    case .timerTicked:
        state.secondsElapsed += 1
        return .none
    case .start:
        guard !state.isTimerActive else { return .none }
        state.isTimerActive = true
        return Effect.timer(id: TimerId(), every: 1, on: environment.mainQueue).map { _ in .timerTicked }
    case .pause:
        state.isTimerActive = false
        return .cancel(id: TimerId())
    }
}
.debugActions("⏰")


let lastFmReducer = Reducer<LastFmState, LastFmAction, SystemEnvironment<LastFmEnvironment>>.combine(
    Reducer { state, action, environment in
        switch action {
        case let .trackAction(trackAction):
            return lastFmTrackReducer.run(&state, trackAction, environment).map { .trackAction($0) }
        case let .userAction(userAction):
            return lastFmUserReducer.run(&state, userAction, environment).map { .userAction($0) }
        case .timerAction(_):
            return .none
        }
    },
    lastFmTimerReducer.pullback(state: \.lastFmTimerState,
                                action: /LastFmAction.timerAction) { $0 }

)


