//
//  OnboardingContentView.swift
//  NepTunes
//
//  Created by Adam Różyński on 17/07/2021.
//

import SwiftUI
import ComposableArchitecture

public struct OnboardingContentView: View {
    
    public let store: Store<OnboardingState, OnboardingAction>
    
    public init(store: Store<OnboardingState, OnboardingAction>) {
        self.store = store
    }
    
    public var body: some View {
        WithViewStore(store) { viewStore in
            VStack(spacing: 0) {
                Group {
                    if viewStore.index == 0 {
                        WelcomeView()
                    } else if viewStore.index == 1 {
                        LoginView(store: store)
                    }
                }
                .transition(.scrollTransition(oldIndex: viewStore.index.oldIndex, newIndex: viewStore.index.currentIndex))
                .ignoresSafeArea(.all, edges: .top)
                Spacer(minLength: 0)
                NavigationControls(index: viewStore.binding(get: \.index, send: OnboardingAction.changePage), numberOfPages: 4)
            }
            .animation(.spring(), value: viewStore.index)
        }
    }

}

private extension AnyTransition {
    static func scrollTransition(oldIndex: Int, newIndex: Int) -> AnyTransition {
        if newIndex > oldIndex {
            let appear = AnyTransition.move(edge: .trailing)
            let disappear = AnyTransition.move(edge: .leading)
            return .asymmetric(insertion: appear, removal: disappear)
        } else {
            let appear = AnyTransition.move(edge: .leading)
            let disappear = AnyTransition.move(edge: .trailing)
            return .asymmetric(insertion: appear, removal: disappear)
        }
    }
}


import Shared
import LastFm
struct OnboardingContainerView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingContentView(store: Store(initialState: OnboardingState(lastFmState: LastFmState()), reducer: onboardingReducer, environment: .live(environment: .live)))
            .frame(width: 460)
            .previewLayout(.sizeThatFits)
    }
}

