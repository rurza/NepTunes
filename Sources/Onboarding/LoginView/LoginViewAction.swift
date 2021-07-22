//
//  LoginViewAction.swift
//  
//
//  Created by Adam Różyński on 22/07/2021.
//

import Foundation

enum LoginViewAction: Equatable {
    case setUsername(String)
    case setPassword(String)
    case signIn
    case signUp
    case signOut
}

extension OnboardingAction {
    static func view(_ localAction: LoginViewAction) -> Self {
        switch localAction {
        case .setPassword(let password):
            return .lastUserFmAction(.setPassword(password))
        case .setUsername(let username):
            return .lastUserFmAction(.setUsername(username))
        case .signIn:
            return .lastUserFmAction(.signIn)
        case .signUp:
            return .lastUserFmAction(.signUp)
        case .signOut:
            return .lastUserFmAction(.signOut)
        }
    }
}
