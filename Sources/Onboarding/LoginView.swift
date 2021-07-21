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

    let store: Store<ViewState, ViewAction>
    @State private var focused: Bool = false

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
                VStack(spacing: 5) {
                    Group {
                        TextField("username/email", text: viewStore.binding(get: \.username, send: ViewAction.setUsername))
                        SecureField("password", text: viewStore.binding(get: \.password, send: ViewAction.setPassword))
                    }
                    .disabled(viewStore.loading)
                    Group {
                        if viewStore.loading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.5)
                        } else {
                            Button("Sign in") { viewStore.send(.signIn) }
                                .disabled(viewStore.unableToLogin)
                        }
                    }
                    .frame(height: 50)
                    
                    Button("Sign Up") { viewStore.send(.signUp) }
                        .buttonStyle(LinkButtonStyle())
                }
                
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: 240)
                .padding()
            }
        }
        .alert(store.scope(state: \.alert,
                           action: { lastFmUserAction in ViewAction.dismissAlert }),
               dismiss: LastFmUserAction.dismissError)
    }
}

extension LoginView {
    
    struct ViewState: Equatable {
        var username: String = ""
        var password: String = ""
        var alert: AlertState<LastFmUserAction>? = nil
        var loading: Bool = false
        
        var unableToLogin: Bool {
            username.count == 0 || password.count == 0 || loading
        }
    }
    
    enum ViewAction: Equatable {
        case setUsername(String)
        case setPassword(String)
        case signIn
        case signUp
        case dismissAlert
    }

}

extension OnboardingState {
    var loginViewState: LoginView.ViewState {
        .init(username: lastFmState.loginState?.username ?? "",
              password: lastFmState.loginState?.password ?? "",
              alert: lastFmState.loginState?.alert,
              loading: lastFmState.loginState?.loading ?? false)
    }
}


extension OnboardingAction {
    static func view(_ localAction: LoginView.ViewAction) -> Self {
        switch localAction {
        case .setPassword(let password):
            return .lastUserFmAction(.setPassword(password))
        case .setUsername(let username):
            return .lastUserFmAction(.setUsername(username))
        case .signIn:
            return .lastUserFmAction(.logIn)
        case .signUp:
            return .lastUserFmAction(.signUp)
        case .dismissAlert:
            return .lastUserFmAction(.dismissError)
        }
    }
}


import LastFm
struct LoginView_Previews: PreviewProvider {
    
    static var store: Store<LoginView.ViewState, LoginView.ViewAction> {
        let lastFmState = LastFmState(loginState: LastFmLoginState(username: "",
                                                                   password: "",
                                                                   loading: true,
                                                                   alert: nil),
                                      userAvatarData: nil)
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
