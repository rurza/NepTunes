//
//  AppAction.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import Foundation

enum AppAction {
    case playerAction(PlayerAction)
    case lastFmAction(LastFmAction)
    case playerScrobblerAction
}
