//
//  AppReducer.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import ComposableArchitecture
import LastFmKit

typealias AppReducer = Reducer<AppState, AppAction, SystemEnvironment<AppEnvironment>>

// the order here matters,
// check: case let .playerAction(.trackAction(.trackDidChange(track))):
let appReducer = AppReducer.combine(
    lastFmReducer
        .pullback(state: \.lastFmState,
                  action: /AppAction.lastFmAction,
                  environment: { _ in
                    .live(environment: LastFmEnvironment(lastFmClient: .live))
                  }),
    playerScrobblerReducer
        .pullback(state: \.playerScrobblerState,
                  action: playerScrobblerCasePath,
                  environment: { $0.map { .live($0) } }), // it's important that this reducer runs before the playerReducer, so the currentTrack isn't set yet
    playerReducer
        .pullback(
            state: \.playerState,
            action: /AppAction.playerAction,
            environment: { appEnvironment in
                .live(environment: appEnvironment.playerEnvironment)
            }
        )
)
