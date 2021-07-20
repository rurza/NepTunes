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
    
    struct ViewState: Equatable {
        var username: String = ""
        var password: String = ""
        
        var unableToLogin: Bool {
            username.count == 0 || password.count == 0
        }
    }
    
    enum ViewAction: Equatable {
        case setUsername(String)
        case setPassword(String)
    }
    
    let store: Store<ViewState, ViewAction>

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
                Form {
                    VStack {
                        TextField("username", text: viewStore.binding(get: \.username, send: ViewAction.setUsername))
                        #warning("support select all etc.")
//                            .textContentType(.username)
                        SecureField("password", text: viewStore.binding(get: \.password, send: ViewAction.setPassword))
                        Button("Log in") { }
                            .frame(minWidth: 120)
                            .padding()
                            .disabled(viewStore.unableToLogin)
                    }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: 240)
                .padding()
            }
        }
    }
}

//struct LoginView_Previews: PreviewProvider {
//    static var previews: some View {
//        LoginView(store: Store(
//                    initialState: ),
//                    reducer: onboardingReducer,
//                    environment: .mock(environment: .live)
//        ))
//        .frame(width: 460)
//    }
//}
