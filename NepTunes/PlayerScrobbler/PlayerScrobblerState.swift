//
//  PlayerScrobblerState.swift
//  NepTunes
//
//  Created by Adam Różyński on 01/07/2021.
//

import Foundation

struct PlayerScrobblerState: Equatable {
    var currentTrack: Track?
    var timerState: LastFmTimerState = LastFmTimerState()
}
