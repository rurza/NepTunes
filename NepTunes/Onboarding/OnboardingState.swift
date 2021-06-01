//
//  OnboardingState.swift
//  NepTunes
//
//  Created by Adam Różyński on 14/05/2021.
//

import Foundation

struct OnboardingState: Equatable {
    @UserDefault(key: "onboardingFinished", defaultValue: false) var onboardingFinished: Bool
}

extension OnboardingState {
    static func == (lhs: OnboardingState, rhs: OnboardingState) -> Bool {
        lhs.onboardingFinished == rhs.onboardingFinished
    }
}
