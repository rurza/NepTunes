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
//    var isTimerActive = false

    var fireInterval: TimeInterval = 0
    // when the timer last started
    // for exmaple it starts with interval 100s
    // the startDate will be set to current date and if the timer will be paused
    // we will calculate the difference to update the fireInterval
    var startDate: Date?
}

