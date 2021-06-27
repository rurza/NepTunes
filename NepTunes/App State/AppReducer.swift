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
                    Reducer { state, action, environment in
                        switch action {
                        case .lastFmAction(.timerAction(.timerTicked)):
                            guard let track = state.playerState.currentPlayerState?.currentTrack else { return Effect(value: .lastFmAction(.timerAction(.invalidate)))}
                            let scrobbleRatio = Double(environment.settings.scrobblePercentage) / 100
                            let secondsElapsed = Double(state.lastFmState.lastFmTimerState.secondsElapsed)
                            guard state.lastFmState.lastFmTimerState.isTimerActive && secondsElapsed >= track.duration * scrobbleRatio else { return .none }
                            return .concatenate(
                                Effect(value: .lastFmAction(.timerAction(.invalidate))),
                                Effect(value: AppAction.lastFmAction(.trackAction(.scrobbleNow(title: track.title, artist: track.artist, albumArtist: track.albumArtist, album: track.album))))
                            )
                        case let .playerAction(.trackAction(.trackDidChange(track))):
                            let playerState = environment.musicApp.state
                            let currentTrack = state.playerState.currentPlayerState?.currentTrack
                            if !track.isTheSameTrackAs(currentTrack) && playerState == .playing {
                                return .concatenate(
                                    Effect(value: .lastFmAction(.timerAction(.invalidate))),
                                    Effect(value: .lastFmAction(.timerAction(.start)))
                                )
                            } else if track.isTheSameTrackAs(currentTrack) {
                                print("🤡 the same track, switching state: \(playerState)")
                                switch playerState {
                                case .paused:
                                    return Effect(value: .lastFmAction(.timerAction(.pause)))
                                case .playing:
                                    return Effect(value: .lastFmAction(.timerAction(.start)))
                                case .stopped:
                                    return Effect(value: .lastFmAction(.timerAction(.invalidate)))
                                case .fastForwarding, .rewinding, .unknown:
                                    return .none
                                }
                            }
                            return .none
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
