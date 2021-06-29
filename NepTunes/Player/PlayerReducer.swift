//
//  PlayerReducer.swift
//  NepTunes
//
//  Created by Adam Różyński on 23/06/2021.
//

import Foundation
import ComposableArchitecture

struct MusicPlayerObservingId: Hashable { }
struct SpotifyPlayerObservingId: Hashable { }

let playerReducer = Reducer<PlayerState, PlayerAction, SystemEnvironment<PlayerEnvironment>> { state, action, environment in
    switch action {
    case let .appAction(.startObservingPlayer(playerType)):
        switch playerType {
        case .musicApp:
            return .merge(
                environment
                    .musicTrackDidChange
                    .map { PlayerAction.trackAction(.playerInfo($0)) }
                    .cancellable(id: MusicPlayerObservingId()),
                environment.getTrackInfo
                    .catch { error in Effect(value: error.track) }
                    .filter { _ in environment.musicApp.state == .playing || environment.musicApp.state == .paused }
                    .eraseToEffect()
                    .map { PlayerAction.trackAction(.playerInfo($0)) }
                )
            .cancellable(id: MusicPlayerObservingId())
        case .spotify:
            #warning("fix!")
            return .none.cancellable(id: SpotifyPlayerObservingId())
        }
        
    case let .appAction(appAction):
        return playerAppReducer.run(&state, appAction, environment).map(PlayerAction.appAction)
    case let .trackAction(trackAction):
        return playerTrackReducer.run(&state, trackAction, environment).map(PlayerAction.trackAction)
    }
}
