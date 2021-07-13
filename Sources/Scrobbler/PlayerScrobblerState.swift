//
//  PlayerScrobblerState.swift
//  NepTunes
//
//  Created by Adam Różyński on 01/07/2021.
//

import Foundation
import PlayersBridge

public struct PlayerScrobblerState: Equatable {
    
    public var currentPlayerState: CurrentPlayerState?
    public var timerState: ScrobblerTimerState
    
    public init(currentPlayerState: CurrentPlayerState? = nil, timerState: ScrobblerTimerState = ScrobblerTimerState()) {
        self.currentPlayerState = currentPlayerState
        self.timerState = timerState
    }
}
