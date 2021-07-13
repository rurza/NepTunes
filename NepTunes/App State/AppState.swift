//
//  AppState.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import Foundation

struct AppState: Equatable {

    var playerState = PlayerState()
    var lastFmState = LastFmState()
    var scrobblerTimerState = ScrobblerTimerState()
    
    var playerScrobblerState: PlayerScrobblerState {
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
    
}
