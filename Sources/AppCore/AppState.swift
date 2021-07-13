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

public struct AppState: Equatable {

    public var playerState = PlayerState()
    public var lastFmState = LastFmState()
    public var scrobblerTimerState = ScrobblerTimerState()
    
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
    
    public init() { }
    
}
