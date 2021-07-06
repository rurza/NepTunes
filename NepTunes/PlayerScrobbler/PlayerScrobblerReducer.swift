//
//  PlayerScrobblerReducer.swift
//  NepTunes
//
//  Created by Adam Różyński on 01/07/2021.
//

import Foundation
import ComposableArchitecture

/// the reducer lifting lastFm and player reducer
let playerScrobblerReducer = Reducer<PlayerScrobblerState, PlayerScrobblerAction, SystemEnvironment<PlayerScrobblerEnvironment>> { state, action, environment in
    switch action {
    /// the timer ticked and we need access to the track to verify if the user was listening it enough long to scrobble it
    case .timerAction(.timerTicked):
        guard let track = state.currentTrack,
              let trackDuration = track.duration // the duration is a safety check here, in theory a track can have nil for the duration
        else { return Effect(value: .timerAction(.invalidate))}
        let scrobbleRatio = Double(environment.settings.scrobblePercentage) / 100
        let secondsElapsed = Double(state.timerState.secondsElapsed)
        guard state.timerState.isTimerActive
                && secondsElapsed >= trackDuration * scrobbleRatio else { return .none }
        return .concatenate(
            Effect(value: .timerAction(.invalidate)),
            Effect(value: .scrobbleNow(title: track.title,
                                       artist: track.artist,
                                       albumArtist: track.albumArtist,
                                       album: track.album))
        )
    case let .playerInfo(track):
        let currentTrack = state.currentTrack
        let playerState = environment.musicApp.state
        
        // only if it's the same track as before, so it means that the player changed it playback state
        // we're using this method, because the track info from notification won't have the artwork
        // so it won't pass standard equality check
        if track.isTheSameTrackAs(currentTrack) {
            /// we're basing decision on the environment's state
            switch playerState {
            case .paused:
                return Effect(value: .timerAction(.pause))
            case .playing:
                return Effect(value: .timerAction(.start))
            case .stopped:
                return Effect(value: .timerAction(.invalidate))
            case .fastForwarding, .rewinding, .unknown:
                return .none
            }
        } else if playerState == .stopped {
            return Effect(value: .timerAction(.invalidate))
        } else {
            return .none
        }
    case .newTrack:
        // we want to invalidate the timer if the new track is available
        // whenever it plays or not
        return Effect(value: .timerAction(.invalidate))
    case let .trackBasicInfoAvailable(track):
        let playerState = environment.musicApp.state
        
        /// `.playerAction(.trackAction(.trackBasicInfoAvailable))` is called only when the track really changed and there is
        /// its duration is available
        if playerState == .playing {
            #warning("support only tracks longer than 30s")
            return Effect(value: .timerAction(.start))
        } else {
            return .none
        }
    case .scrobbleNow:
        return .none
    case .updateNowPlaying:
        return .none
    case .timerAction:
        return .none
    }
}

let playerScrobblerCasePath = CasePath<AppAction, PlayerScrobblerAction> { playerScrobblerAction in
    switch playerScrobblerAction {
    case let .newTrack(track):
        return .playerAction(.trackAction(.newTrack(track)))
    case let .playerInfo(track):
        return .playerAction(.trackAction(.playerInfo(track)))
    case let .trackBasicInfoAvailable(track):
        return .playerAction(.trackAction(.trackBasicInfoAvailable(track)))
    case let .timerAction(timerAction):
        return .lastFmAction(.timerAction(timerAction))
    case let .scrobbleNow(title: title, artist: artist, albumArtist: albumArtist, album: album):
        return .lastFmAction(.trackAction(.scrobbleNow(title: title, artist: artist, albumArtist: albumArtist, album: album)))
    case let .updateNowPlaying(title: title, artist: artist, albumArtist: albumArtist, album: album):
        return .lastFmAction(.trackAction(.updateNowPlaying(title: title, artist: artist, albumArtist: albumArtist, album: album)))
    }
} extract: { appAction in
    switch appAction {
    case let .playerAction(.trackAction(.newTrack(track))):
        return .newTrack(track)
    case let .playerAction(.trackAction(.playerInfo(track))):
        return .playerInfo(track)
    case let .playerAction(.trackAction(.trackBasicInfoAvailable(track))):
        return .trackBasicInfoAvailable(track)
    case let .lastFmAction(.timerAction(action)):
        return .timerAction(action)
    case let .lastFmAction(.trackAction(.scrobbleNow(title: title, artist: artist, albumArtist: albumArtist, album: album))):
        return .scrobbleNow(title: title, artist: artist, albumArtist: albumArtist, album: album)
    case let .lastFmAction(.trackAction(.updateNowPlaying(title: title, artist: artist, albumArtist: albumArtist, album: album))):
        return .updateNowPlaying(title: title, artist: artist, albumArtist: albumArtist, album: album)
    default:
        return nil
    }
}

