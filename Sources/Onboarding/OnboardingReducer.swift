//
//  OnboardingReducer.swift
//  
//
//  Created by Adam Różyński on 20/07/2021.
//

import ComposableArchitecture
import Shared
import LastFm

public let onboardingReducer = Reducer<OnboardingState, OnboardingAction, SystemEnvironment<LastFmEnvironment>> { state, action, environment in
    switch action {
    case .toggleLaunchAtLogin:
        state.launchAtLogin.toggle()
        return .none
    case .changePage(index: let index):
        state.index = index
        return .none
    case .lastUserFmAction:
        return .none
    }
}
.combined(with:
            lastFmUserReducer.pullback(state: \.lastFmState,
                                       action: /OnboardingAction.lastUserFmAction,
                                       environment: { $0 }
            ))
