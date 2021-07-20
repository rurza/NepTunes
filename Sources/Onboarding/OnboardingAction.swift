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
