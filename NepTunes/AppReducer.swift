//
//  AppReducer.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import ComposableArchitecture

typealias AppReducer = Reducer<AppState, AppAction, AppEnvironment>

let appReducer = AppReducer.combine(
    lastFmReducer.pullback(state: \.lastFmState,
                           action: /AppAction.lastFmAction,
                           environment: { _ in AppEnvironment() }),
    AppReducer { state, action, environment in
        switch action {
        case let .onboardingAction(onboarding):
            switch onboarding {
            case .finishOnboarding:
                state.onboardingFinished = true
            }
        case let .newPlayerIsAvailable(player):
            if state.currentPlayer == nil {
                state.currentPlayer = player
            }
        default:
            ()
        }
        return .none
    }
).debug()
