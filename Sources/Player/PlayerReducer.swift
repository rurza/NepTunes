//
//  PlayerReducer.swift
//  NepTunes
//
//  Created by Adam Różyński on 23/06/2021.
//

import Foundation
import ComposableArchitecture
import Shared

struct MusicPlayerObservingId: Hashable { }
struct SpotifyPlayerObservingId: Hashable { }

public let playerReducer = Reducer<PlayerState, PlayerAction, SystemEnvironment<PlayerEnvironment>> { state, action, environment in
    switch action {
    case let .appAction(.startObservingPlayer(playerType)):
        switch playerType {
        case .musicApp:
            return .merge(
                environment
                    .musicTrackDidChange
                    .map { PlayerAction.trackAction(.playerInfo($0)) }
                    .cancellable(id: MusicPlayerObservingId()),
                environment.getTrackInfo(environment.musicApp)
                    .filter { _ in environment.musicApp.state == .playing || environment.musicApp.state == .paused }
                    .map { PlayerAction.trackAction(.playerInfo($0)) }
                    .catch { error in Effect(value: .trackAction(.noTrack)) }
                    .eraseToEffect()
            )
            .cancellable(id: MusicPlayerObservingId())
        case .spotify:
            return .merge(
                environment
                    .spotifyTrackDidChange
                    .map { PlayerAction.trackAction(.playerInfo($0)) }
                    .cancellable(id: SpotifyPlayerObservingId()),
                environment
                    .getTrackInfo(environment.spotifyApp)
                    .filter { _ in environment.spotifyApp.state == .playing || environment.spotifyApp.state == .paused }
                    .map { PlayerAction.trackAction(.playerInfo($0)) }
                    .catch { error in Effect(value: .trackAction(.noTrack)) }
                    .eraseToEffect()

            )
            .cancellable(id: SpotifyPlayerObservingId())
        }
        
    case let .appAction(appAction):
        return playerAppReducer.run(&state, appAction, environment.map { $0.appEnvironment }).map(PlayerAction.appAction)
    case let .trackAction(trackAction):
        return playerTrackReducer.run(&state, trackAction, environment).map(PlayerAction.trackAction)
    }
}
