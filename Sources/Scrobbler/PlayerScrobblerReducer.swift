//
//  PlayerScrobblerReducer.swift
//  NepTunes
//
//  Created by Adam Różyński on 01/07/2021.
//

import Foundation
import ComposableArchitecture
import Shared

/// the reducer lifting lastFm and player reducer
public let playerScrobblerReducer = Reducer<PlayerScrobblerState, PlayerScrobblerAction, SystemEnvironment<PlayerScrobblerEnvironment>>.combine(
    scrobblerTimerReducer.pullback(state: \.timerState,
                                   action: /PlayerScrobblerAction.timerAction,
                                   environment: { $0.map { _ in VoidEnvironment() }}),
    Reducer { state, action, environment in
        switch action {
        /// the timer ticked and we need access to the track to verify if the user was listening it enough long to scrobble it
        case .timerAction(.timerTicked):
            guard let currentPlayerType = state.currentPlayerState?.playerType else {
                return Effect(value: .timerAction(.invalidate))
            }
            // we're getting the track directly from the player instead of state, because Spotify can play the ad and we want to invalidate the timer
            // it's because Spotify doesn't send any notification when the ad started playing
            guard let track = environment.localEnvironment.playerForPlayerType(currentPlayerType).currentTrack,
                  let trackDuration = track.duration // the duration is a safety check here, in theory a track can have nil for the duration
            else { return Effect(value: .timerAction(.invalidate))}

            return Effect(value: .scrobbleNow(title: track.title,
                                              artist: track.artist,
                                              albumArtist: track.albumArtist,
                                              album: track.album))
        case let .newEventFromPlayerWithTrack(track):
            guard let playerType = state.currentPlayerState?.playerType else { return .none }
            guard let currentTrack = state.currentPlayerState?.currentTrack else { return .none }
            let playerState = environment.localEnvironment.playerForPlayerType(playerType).state
            
            // only if it's the same track as before, so it means that the player changed it playback state;
            //
            // we're using `isTheSameTrackAs` method, because the track info from the notification won't have the artwork
            // so it won't pass standard equality check
            if track.isTheSameTrackAs(currentTrack) {
                /// we're basing decision on the environment's state
                switch playerState {
                case .paused, .playing:
                    if state.timerState.fireInterval > 0 {
                        return Effect(value: .timerAction(.toggle))
                    } else {
                        return Effect(value: .scrobblerTimerShouldStartForTrack(currentTrack))
                    }
                case .stopped:
                    return Effect(value: .timerAction(.invalidate))
                case .unknown:
                    return .none
                }
            } else if playerState == .stopped {
                return Effect(value: .timerAction(.invalidate))
            } else {
                return .none
            }
        case .playerChangedTheTrack:
            // we want to invalidate the timer if the new track is available
            // whenever it plays or not
            return Effect(value: .timerAction(.invalidate))
        case let .scrobblerTimerShouldStartForTrack(track):
            guard let trackDuration = track.duration else { return .none }
            // it's better to quietly return here
            guard let currentPlayerType = state.currentPlayerState?.playerType else { return .none }
            let playerState = environment.localEnvironment.playerForPlayerType(currentPlayerType).state
            
            /// `.playerAction(.trackAction(.trackBasicInfoAvailable))` is called only when the track really changed and there is
            /// its duration is available
            if playerState == .playing, trackDuration >= 30 {
                let scrobbleRatio = Double(environment.settings.scrobblePercentage) / 100
                let fireInterval = trackDuration * scrobbleRatio
                return Effect(value: .timerAction(.start(fireInterval: fireInterval)))
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
)
.debugActions("playerScrobblerReducer")


