//
//  SwiftUIView.swift
//  
//
//  Created by Adam Różyński on 20/07/2021.
//

import SwiftUI
import ComposableArchitecture
import Shared

struct LoginView: View {
    
    let store: Store<OnboardingState, OnboardingAction>
    @State var username: String = ""
    @State var password: String = ""
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                ZStack {
                    Color(.sRGB, red: 213/255, green: 16/255, blue: 7/255, opacity: 1)
                        .frame(height: 240)
                    Image("lastfm", bundle: Bundle.module)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 70)
                        .foregroundColor(.white)
                }
//                Form {
                    VStack {
                        TextField("username", text: $username)
//                            .textContentType(.username)
                        TextField("password", text: $password)
                            .textContentType(.password)
                        Button("Log in") { }
                            .frame(minWidth: 120)
                            .padding()
                            .disabled(viewStore.lastFmState.loginState?.username != nil && viewStore.lastFmState.loginState?.password != nil)
                    }
//                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: 240)
                .padding()
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(store: Store(
                    initialState: OnboardingState(lastFmState: .init()),
                    reducer: onboardingReducer,
                    environment: .mock(environment: .live)
        ))
        .frame(width: 460)
    }
}
