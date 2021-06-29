//
//  LastFmState.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import Foundation

struct LastFmState: Equatable {
    var loginState: LastFmLoginState?
    var lastFmTimerState = LastFmTimerState()
}

struct LastFmLoginState: Equatable {
    var username: String?
    var password: String?
}

struct LastFmTimerState: Equatable {
    /// not sure if this is needed
    var isTimerActive = false
    var secondsElapsed = 0
}

