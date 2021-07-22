//
//  LoginHeaderView.swift
//  
//
//  Created by Adam Różyński on 22/07/2021.
//

import SwiftUI
import ComposableArchitecture
import Cocoa
import LastFm

struct LoginHeaderView: View {
    
    let store: Store<LoginViewState, LoginViewAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            ZStack {
                Color.black
                    .frame(height: 240)
                if viewStore.isLoggedIn {
                    if let userAvatarData = viewStore.userAvatarData {
                        if let nsImage = NSImage(data: userAvatarData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 70)
                                .clipShape(Circle())
                        } else {
                            lastFmImage
                        }
                    } else {
                        ProgressView()
                            .scaleEffect(0.5)
                            .colorScheme(.dark)
                    }
                } else {
                    lastFmImage
                }
            }
        }
    }
    
    var lastFmImage: some View {
        Image("lastfm", bundle: Bundle.module)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 70)
            .foregroundColor(.white)
    }
}


struct LoginHeaderView_Previews: PreviewProvider {
    static var store: Store<LoginViewState, LoginViewAction> {
        let lastFmState = LastFmState(loginState: LastFmLoginState(username: "",
                                                                   password: "",
                                                                   loading: false,
                                                                   alert: nil),
                                      userAvatarData: nil,
                                      userSessionKey: "")
        let store = Store(initialState: OnboardingState(lastFmState: lastFmState),
                          reducer: onboardingReducer,
                          environment: .live(environment: .live))
        return store.scope(state: \.loginViewState,
                           action: { OnboardingAction.view($0) })
    }
    
    static var previews: some View {
        LoginHeaderView(store: store)
            .frame(width: 460)
    }
}
