//
//  AppAction.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import Foundation

enum AppAction {
    case lastFmAction(LastFmAction)
    case onboardingAction(OnboardingAction)
    case newPlayerIsAvailable(PlayerType?)
    case trackChanged(track: Track, player: Player)
}
