//
//  AppLifecycleReducer.swift
//  
//
//  Created by Adam Różyński on 16/07/2021.
//

import Foundation
import Shared
import ComposableArchitecture

public let appLifecycleReducer = Reducer<AppState, AppAction, SystemEnvironment<AppEnvironment>> { state, action, environment in
    switch action {
    case .appLifecycleAction(.appDidLaunch):
        if !environment.settings.onboardingIsDone {
            state.shouldShowOnboarding = true
        }
        return Effect(value: .playerAction(.appAction(.startObservingPlayers)))
    default:
        return .none
    }
}
