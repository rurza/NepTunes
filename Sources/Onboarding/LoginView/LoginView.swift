//
//  SwiftUIView.swift
//  
//
//  Created by Adam Różyński on 20/07/2021.
//

import SwiftUI
import ComposableArchitecture
import Shared
import SharedUI


struct LoginView: View {

    let store: Store<LoginViewState, LoginViewAction>

    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                LoginHeaderView(store: store)
                VStack(spacing: 5) {
                    if viewStore.isLoggedIn {
                        HStack {
                            Text("Hello,")
                                .font(.title)
                            Text(viewStore.username)
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        Button("Sign Out") { viewStore.send(.signOut) }
                        Spacer()
                    } else {
                        Form {
                            TextField("username", text: viewStore.binding(get: \.username, send: LoginViewAction.setUsername))
                            SecureField("password", text: viewStore.binding(get: \.password, send: LoginViewAction.setPassword))
                        }
                        .disabled(viewStore.loading)
                        Group {
                            if viewStore.loading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.5)
                            } else {
                                Button(action: { viewStore.send(.signIn) }) {
                                    Text("Sign In")
                                        .frame(minWidth: 120)
                                }
                                .disabled(viewStore.unableToLogin)
                                .keyboardShortcut(.defaultAction)
                            }
                        }
                        .frame(height: 50)
                        Button("Sign Up") { viewStore.send(.signUp) }
                            .buttonStyle(LinkButtonStyle())
                    }
                    
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: 240)
                .padding()
            }
        }
    }
}

import LastFm
struct LoginView_Previews: PreviewProvider {
    
    static var store: Store<LoginViewState, LoginViewAction> {
        let lastFmState = LastFmState(loginState: LastFmLoginState(username: "rurzynski",
                                                                   password: "",
                                                                   loading: false,
                                                                   alert: nil),
                                      userAvatarData: nil, userSessionKey: "")
        let store = Store(initialState: OnboardingState(lastFmState: lastFmState),
                          reducer: onboardingReducer,
                          environment: .live(environment: .live))
        return store.scope(state: \.loginViewState,
                           action: { OnboardingAction.view($0) })
    }
    
    static var previews: some View {
        LoginView(store: store)
        .frame(width: 460)
    }
}

