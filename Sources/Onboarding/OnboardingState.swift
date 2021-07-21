//
//  OnboardingState.swift
//  
//
//  Created by Adam Różyński on 20/07/2021.
//

import Foundation
import LastFm

@dynamicMemberLookup
public struct OnboardingState: Equatable {
    
    public var onboardingSubstate: OnboardingSubstate = OnboardingSubstate()
    public var lastFmState: LastFmState
    
    public init(onboardingSubstate: OnboardingSubstate = OnboardingSubstate(), lastFmState: LastFmState) {
        self.onboardingSubstate = onboardingSubstate
        self.lastFmState = lastFmState
    }
    
    public subscript<Value>(
        dynamicMember keyPath: WritableKeyPath<OnboardingSubstate, Value>
    ) -> Value {
        get { self.onboardingSubstate[keyPath: keyPath] }
        set { self.onboardingSubstate[keyPath: keyPath] = newValue }
    }
}

public struct OnboardingSubstate: Equatable {
    internal var index: PageIndex = 0
    public var launchAtLogin: Bool = false
    
    public init() { }

}
