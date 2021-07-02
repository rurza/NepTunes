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
    
    var playerScrobblerState: PlayerScrobblerState {
        get {
            PlayerScrobblerState(currentTrack: playerState.currentPlayerState?.currentTrack, timerState: lastFmState.lastFmTimerState)
        }
        set {
            playerState.currentPlayerState?.currentTrack = newValue.currentTrack
            lastFmState.lastFmTimerState = newValue.timerState
        }
    }
    
}
