//
//  PlayerScrobblerCasePath.swift
//  
//
//  Created by Adam Różyński on 13/07/2021.
//

import Foundation
import Scrobbler
import ComposableArchitecture
import Player

let playerScrobblerCasePath = CasePath<AppAction, PlayerScrobblerAction> { playerScrobblerAction in
    switch playerScrobblerAction {
    case let .playerChangedTheTrack(track):
        return .playerAction(.trackAction(.newTrack(track)))
    case let .newEventFromPlayerWithTrack(track):
        return .playerAction(.trackAction(.playerInfo(track)))
    case let .scrobblerTimerShouldStartForTrack(track):
        return .playerAction(.trackAction(.trackBasicInfoAvailable(track)))
    case let .timerAction(timerAction):
        return .scrobblerTimerAction(timerAction)
    case let .scrobbleNow(track):
        return .lastFmAction(.trackAction(.scrobbleNow(track)))
    case let .updateNowPlaying(track):
        return .lastFmAction(.trackAction(.updateNowPlaying(track)))
    }
} extract: { appAction in
    switch appAction {
    case let .playerAction(.trackAction(.newTrack(track))):
        return .playerChangedTheTrack(track)
    case let .playerAction(.trackAction(.playerInfo(track))):
        return .newEventFromPlayerWithTrack(track)
    case let .playerAction(.trackAction(.trackBasicInfoAvailable(track))):
        return .scrobblerTimerShouldStartForTrack(track)
    case let .scrobblerTimerAction(action):
        return .timerAction(action)
    case let .lastFmAction(.trackAction(.scrobbleNow(track))):
        return .scrobbleNow(track)
    case let .lastFmAction(.trackAction(.updateNowPlaying(track))):
        return .updateNowPlaying(track)
    default:
        return nil
    }
}
