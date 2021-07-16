//
//  AppAction.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import Foundation
import Scrobbler
import LastFm
import Player

public enum AppAction {
    case playerAction(PlayerAction)
    case lastFmAction(LastFmAction)
    case scrobblerTimerAction(ScrobblerTimerAction)
    case appLifecycleAction(AppLifecycleAction)
}
