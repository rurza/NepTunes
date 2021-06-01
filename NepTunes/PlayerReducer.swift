//
//  PlayerReducer.swift
//  NepTunes
//
//  Created by Adam Różyński on 01/06/2021.
//

import Foundation
import ComposableArchitecture

let playerReducer = Reducer<PlayerState, PlayerAction, PlayerEnvironment> { state, action, environment in
    
    struct PlayerObservingId: Hashable { }
    
    switch action {
    case .startObservingPlayers:
        return .merge(
            environment
                .newPlayerLaunched
                .map { .newPlayerIsAvailable($0) },
            environment
                .playerQuitEffect
                .map { .playerDidQuit($0) }
        )
        .cancellable(id: PlayerObservingId())
    case let .newPlayerIsAvailable(newPlayer):
        if !state.availablePlayers.contains(newPlayer) {
            state.availablePlayers.append(newPlayer)
        }
        if state.currentPlayer == nil && state.availablePlayers.count == 1 {
            state.currentPlayer = newPlayer
        }
        return .none
    case let .currentPlayerDidChange(player):
        state.currentPlayer = player
        return .none
    case let .playerDidQuit(player):
        state.availablePlayers.removeAll(where: { $0 == player })
        if state.currentPlayer == player && state.availablePlayers.count == 0 {
            state.currentPlayer = nil
        } else if state.currentPlayer == player {
            state.currentPlayer = state.availablePlayers.first
        }
        return .none
    case .stopObservingPlayers:
        return .cancel(id: PlayerObservingId())
    }
}
