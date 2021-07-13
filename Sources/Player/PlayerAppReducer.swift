//
//  PlayerAppReducer.swift
//  NepTunes
//
//  Created by Adam Różyński on 01/06/2021.
//

import Foundation
import ComposableArchitecture
import Combine
import Shared
import PlayersBridge

public let playerAppReducer = Reducer<PlayerState, PlayerAppAction, SystemEnvironment<PlayerAppEnvironment>> { state, action, environment in
    
    struct AllPlayersObservingId: Hashable { }
    
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
        .cancellable(id: AllPlayersObservingId())
        if let playerTypes = environment.currentlyRunningPlayers() {
            let playersAreAvailableEffects = Effect.concatenate(playerTypes.map { Effect<PlayerAppAction, Never>(value: .newPlayerIsAvailable($0)) })
            return .merge(effects, playersAreAvailableEffects)
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
            return Effect(value: .startObservingPlayer(playerType))
        } else {
            state.currentPlayerState = nil
            return .none
        }
    case let .playerDidQuit(playerType):
        let stopObservingQuittedPlayerEffect = Effect<PlayerAppAction, Never>(value: .stopObservingPlayer(playerType))
        state.availablePlayers.removeAll(where: { $0 == playerType })
        if state.currentPlayerState?.playerType == playerType && state.availablePlayers.count == 0  {
            return .concatenate(
                stopObservingQuittedPlayerEffect,
                Effect(value: .currentPlayerDidChange(nil))
            )
        } else if state.currentPlayerState?.playerType == playerType,
                  let availablePlayerType = state.availablePlayers.first {// current player quit and there is more players available
            return .concatenate(
                stopObservingQuittedPlayerEffect,
                Effect(value: .currentPlayerDidChange(availablePlayerType))
            )
        }
        return .none
    case .stopObservingPlayers:
        return .cancel(id: AllPlayersObservingId())
    case let .startObservingPlayer(playerType):
        /// part of it is handled in the parent reducer
        return .none
    case let .stopObservingPlayer(playerType):
        switch playerType {
        case .musicApp:
            return .cancel(id: MusicPlayerObservingId())
        case .spotify:
            return .cancel(id: SpotifyPlayerObservingId())
        }
    }
}
.debugActions("👩‍🎤🧑‍🎤")

