//
//  OnboardingAction.swift
//  
//
//  Created by Adam Różyński on 20/07/2021.
//

import Foundation
import LastFm

public enum OnboardingAction: Equatable {
    case lastUserFmAction(LastFmUserAction)
    case toggleLaunchAtLogin
    case changePage(index: PageIndex)
}

extension OnboardingAction {
    static func view(_ localAction: LoginView.ViewAction) -> Self {
        switch localAction {
        case .setPassword(let password):
            return .lastUserFmAction(.setPassword(password))
        case .setUsername(let username):
            return .lastUserFmAction(.setUsername(username))
        }
    }
}
