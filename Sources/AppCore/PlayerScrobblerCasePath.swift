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
    case let .scrobbleNow(title: title, artist: artist, albumArtist: albumArtist, album: album):
        return .lastFmAction(.trackAction(.scrobbleNow(title: title, artist: artist, albumArtist: albumArtist, album: album)))
    case let .updateNowPlaying(title: title, artist: artist, albumArtist: albumArtist, album: album):
        return .lastFmAction(.trackAction(.updateNowPlaying(title: title, artist: artist, albumArtist: albumArtist, album: album)))
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
    case let .lastFmAction(.trackAction(.scrobbleNow(title: title, artist: artist, albumArtist: albumArtist, album: album))):
        return .scrobbleNow(title: title, artist: artist, albumArtist: albumArtist, album: album)
    case let .lastFmAction(.trackAction(.updateNowPlaying(title: title, artist: artist, albumArtist: albumArtist, album: album))):
        return .updateNowPlaying(title: title, artist: artist, albumArtist: albumArtist, album: album)
    default:
        return nil
    }
}
