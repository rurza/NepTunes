//
//  AppReducer.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import ComposableArchitecture
import LastFmKit

typealias AppReducer = Reducer<AppState, AppAction, SystemEnvironment<AppEnvironment>>

// the order here matters,
// check: case let .playerAction(.trackAction(.trackDidChange(track))):
let appReducer = AppReducer.combine(
    lastFmReducer
        .pullback(state: \.lastFmState,
                  action: /AppAction.lastFmAction,
                  environment: { _ in
                    .live(environment: LastFmEnvironment(lastFmClient: .live))
                  })
        .combined(with:
                    /// it's important that this reducer runs before the playerReducer, so the currentTrack isn't set yet
                    Reducer { state, action, environment in
                        switch action {
                        /// the timer ticked and we need access to the track to verify if the user was listening it enough long to scrobble it
                        case .lastFmAction(.timerAction(.timerTicked)):
                            guard let track = state.playerState.currentPlayerState?.currentTrack,
                                  let trackDuration = track.duration // the duration is a safety check here, in theory a track can have nil for the duration
                            else { return Effect(value: .lastFmAction(.timerAction(.invalidate)))}
                            let scrobbleRatio = Double(environment.settings.scrobblePercentage) / 100
                            let secondsElapsed = Double(state.lastFmState.lastFmTimerState.secondsElapsed)
                            guard state.lastFmState.lastFmTimerState.isTimerActive
                                    && secondsElapsed >= trackDuration * scrobbleRatio else { return .none }
                            return .concatenate(
                                Effect(value: .lastFmAction(.timerAction(.invalidate))),
                                Effect(value: AppAction.lastFmAction(.trackAction(.scrobbleNow(title: track.title,
                                                                                               artist: track.artist,
                                                                                               albumArtist: track.albumArtist,
                                                                                               album: track.album))))
                            )
                        case let .playerAction(.trackAction(.playerInfo(track))):
                            let currentTrack = state.playerState.currentPlayerState?.currentTrack
                            let playerState = environment.musicApp.state
                            
                            // only if it's the same track as before, so it means that the player changed it playback state
                            // we're using this method, because the track info from notification won't have the artwork
                            // so it won't pass standard equality check
                            if track.isTheSameTrackAs(currentTrack) {
                                /// we're basing decision on the environment's state
                                switch playerState {
                                case .paused:
                                    return Effect(value: .lastFmAction(.timerAction(.pause)))
                                case .playing:
                                    #warning("support only tracks longer than 30s")
                                    return Effect(value: .lastFmAction(.timerAction(.start)))
                                case .stopped:
                                    return Effect(value: .lastFmAction(.timerAction(.invalidate)))
                                case .fastForwarding, .rewinding, .unknown:
                                    return .none
                                }
                            } else if playerState == .stopped {
                                return Effect(value: .lastFmAction(.timerAction(.invalidate)))
                            } else {
                                return .none
                            }
                        case .playerAction(.trackAction(.newTrack)):
                            // we want to invalidate the timer if the new track is available
                            // whenever it plays or not
                            return Effect(value: .lastFmAction(.timerAction(.invalidate)))
                        case let .playerAction(.trackAction(.trackBasicInfoAvailable(track))):
                            let playerState = environment.musicApp.state
                            
                            /// `.playerAction(.trackAction(.trackBasicInfoAvailable))` is called only when the track really changed and there is
                            /// its durationa available
                            if playerState == .playing {
                                return Effect(value: .lastFmAction(.timerAction(.start)))
                            } else {
                                return .none
                            }
                        default:
                            return .none
                        }
                    }
        ),
    playerReducer
        .pullback(
            state: \.playerState,
            action: /AppAction.playerAction,
            environment: { appEnvironment in
                appEnvironment.map {
                    PlayerEnvironment.live(appEnvironment: $0)
                }
            }
        )
)
