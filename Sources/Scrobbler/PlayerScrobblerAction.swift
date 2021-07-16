//
//  PlayerScrobblerAction.swift
//  NepTunes
//
//  Created by Adam Różyński on 01/07/2021.
//

import Foundation
import Shared

public enum PlayerScrobblerAction: Equatable {
    case timerAction(ScrobblerTimerAction)
    case newEventFromPlayerWithTrack(Track)
    case playerChangedTheTrack(Track)
    case scrobblerTimerShouldStartForTrack(Track)
    case scrobbleNow(Track)
    case updateNowPlaying(Track)
}
