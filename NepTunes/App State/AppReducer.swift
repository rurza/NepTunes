//
//  AppReducer.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import ComposableArchitecture
import LastFmKit

typealias AppReducer = Reducer<AppState, AppAction, SystemEnvironment<AppEnvironment>>

let appReducer = AppReducer.combine(
    playerReducer
        .pullback(
            state: \.playerState,
            action: /AppAction.playerAction,
            environment: { appEnvironment in
                appEnvironment.map {
                    PlayerEnvironment.live(appEnvironment: $0)
                }
            }
        ),
    lastFmReducer
        .pullback(state: \.lastFmState,
                  action: /AppAction.lastFmAction,
                  environment: { _ in
                    .live(environment: LastFmEnvironment(lastFmClient: .live))
                  })
        .combined(with:
                    Reducer { state, action, environment in
                        switch action {
                        case let .playerAction(.trackAction(.trackDidChange(track))):
                            return Effect(value: AppAction.lastFmAction(.trackDidChange))
                        default:
                            return .none
                        }
                    }
        )
)
