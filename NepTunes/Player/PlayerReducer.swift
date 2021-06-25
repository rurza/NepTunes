//
//  PlayerReducer.swift
//  NepTunes
//
//  Created by Adam Różyński on 23/06/2021.
//

import Foundation
import ComposableArchitecture

struct MusicPlayerObservingId: Hashable { }


let playerReducer = Reducer<SharedState<PlayerState>, PlayerAction, SystemEnvironment<PlayerEnvironment>> { state, action, environment in
    switch action {
    case .appAction(.startObservingMusicPlayer):
        return .merge(
            environment
                .musicTrackDidChange
                .map { PlayerAction.trackAction(.trackDidChange($0)) }
                .cancellable(id: MusicPlayerObservingId()),
            environment.getTrackInfo
                .catch { error in Effect.none }
                .eraseToEffect()
                .map { PlayerAction.trackAction(.trackDidChange($0)) }
            )
    case let .appAction(appAction):
        return playerAppReducer.run(&state, appAction, environment).map(PlayerAction.appAction)
    case let .trackAction(trackAction):
        return playerTrackReducer.run(&state, trackAction, environment).map(PlayerAction.trackAction)
    }
}
