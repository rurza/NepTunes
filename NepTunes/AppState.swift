//
//  AppState.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import Foundation

struct AppState {
    var lastFmState: LastFmState = LastFmState()
    @UserDefault(key: "onboardingFinished", defaultValue: false) var onboardingFinished: Bool
    var currentPlayer: Player? = nil
}
