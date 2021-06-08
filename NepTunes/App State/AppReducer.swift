//
//  AppReducer.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import ComposableArchitecture

typealias AppReducer = Reducer<AppState, AppAction, SystemEnvironment<AppEnvironment>>

let appReducer = AppReducer.combine(
    .init { state, action, environment in
        return .none
    },
    playerReducer
        .pullback(
            state: \.playerState,
            action: /AppAction.playerAction,
            environment: {
                .live(
                    environment: PlayerEnvironment(newPlayerLaunched: $0.newPlayerLaunched,
                                                   playerQuit: $0.playerQuit,
                                                   musicTrackDidChange: $0.musicTrackDidChange,
                                                   musicApp: $0.musicApp,
                                                   getTrackInfo: getTrackCoverFromPlayer($0.musicApp),
                                                   artworkDownloader: $0.artworkDownloader)
                )
                
            }
        )
).debug()
