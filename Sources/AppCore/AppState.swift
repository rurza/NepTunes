//
//  AppState.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import Foundation
import LastFm
import Scrobbler
import Player
import Onboarding

public struct AppState: Equatable {

    public var playerState = PlayerState()
    public var lastFmState = LastFmState()
    public var scrobblerTimerState = ScrobblerTimerState()
    private var onboardingSubstate: OnboardingSubstate? = nil
    
    public var playerScrobblerState: PlayerScrobblerState {
        get {
            PlayerScrobblerState(currentPlayerState: playerState.currentPlayerState,
                                 timerState: scrobblerTimerState)
        }
        set {
            // we don't want to update the state of the `currentPlayerState` here
            // because the reducer doesn't change it
            
            scrobblerTimerState = newValue.timerState
        }
    }
    
    public var onboardingState: OnboardingState? {
        get {
            if let onboardingSubstate = onboardingSubstate {
                return OnboardingState(onboardingSubstate: onboardingSubstate, lastFmState: lastFmState)
            } else {
                return nil
            }
        }
        set {
            if let state = newValue {
                lastFmState = state.lastFmState
            }
            onboardingSubstate = newValue?.onboardingSubstate
        }
    }
    
    public init() { }
    
}
