//
//  LaunchAtLoginView.swift
//  NepTunes
//
//  Created by Adam Różyński on 20/07/2021.
//

import SwiftUI
import ComposableArchitecture

struct LaunchAtLoginView: View {

    let store: Store<OnboardingState, OnboardingAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            Toggle("Launch at login", isOn: viewStore.binding(get: \.launchAtLogin, send: OnboardingAction.toggleLaunchAtLogin))
        }
    }
}

import LastFm
struct LaunchAtLoginView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchAtLoginView(store: Store(
                            initialState: OnboardingState(lastFmState: LastFmState()),
                            reducer: onboardingReducer,
                            environment: .mock(environment: .live)
        ))
    }
}
