//
//  PlayerAppReducer.swift
//  NepTunes
//
//  Created by Adam Różyński on 01/06/2021.
//

import Foundation
import ComposableArchitecture
import Combine


let playerAppReducer = Reducer<PlayerState, PlayerAppAction, SystemEnvironment<PlayerEnvironment>> { state, action, environment in
    
    struct PlayerObservingId: Hashable { }
    
    switch action {
    case .startObservingPlayers:
        let effects: Effect<PlayerAppAction, Never> = Effect.merge(
            environment
                .newPlayerLaunched
                .map { .newPlayerIsAvailable($0) },
            environment
                .playerQuit
                .map { .playerDidQuit($0) }
        )
        .cancellable(id: PlayerObservingId())
        if let playerType = environment.currentlyRunningPlayer() {
            return .merge(effects, Effect<PlayerAppAction, Never>(value: .newPlayerIsAvailable(playerType)))
        }
        return effects
    case let .newPlayerIsAvailable(newPlayerType):
        if !state.availablePlayers.contains(newPlayerType) {
            state.availablePlayers.append(newPlayerType)
        }
        if case .none = state.currentPlayerState, state.availablePlayers.count == 1 {
            return Effect(value: .currentPlayerDidChange(newPlayerType))
        }
        return .none
    case let .currentPlayerDidChange(playerType):
        if let playerType = playerType {
            state.currentPlayerState = CurrentPlayerState(playerType: playerType)
        } else {
            state.currentPlayerState = nil
        }
        return Effect(value: .startObservingMusicPlayer)
    case let .playerDidQuit(playerType):
        state.availablePlayers.removeAll(where: { $0 == playerType })
        if state.currentPlayerState?.playerType == playerType && state.availablePlayers.count == 0  {
            return Effect(value: .currentPlayerDidChange(nil))
        } else if state.currentPlayerState?.playerType == playerType,
                  let availablePlayerType = state.availablePlayers.first {// current player quit and there is more players available
            return Effect(value: .currentPlayerDidChange(availablePlayerType))
        }
        return .none
    case .stopObservingPlayers:
        return .cancel(id: PlayerObservingId())
    case .startObservingMusicPlayer:
        /// handled in the parent reducer
        return .none
    case .stopObservingMusicPlayer:
        return .cancel(id: MusicPlayerObservingId())
    
    }
}

