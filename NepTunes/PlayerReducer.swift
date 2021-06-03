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
    struct MusicPlayerObservingId: Hashable { }
    struct TimerId: Hashable { }
    
    switch action {
    case .startObservingPlayers:
        return .merge(
            environment
                .newPlayerLaunched
                .map { .newPlayerIsAvailable($0) },
            environment
                .playerQuit
                .map { .playerDidQuit($0) }
        )
        .cancellable(id: PlayerObservingId())
    case let .newPlayerIsAvailable(newPlayerType):
        if !state.availablePlayers.contains(newPlayerType) {
            state.availablePlayers.append(newPlayerType)
        }
        if case .none = state.currentPlayerState, state.availablePlayers.count == 1 {
            return Effect(value: .currentPlayerDidChange(newPlayerType))
        }
        return .none
    case let .currentPlayerDidChange(playerType):
        state.currentPlayerState = CurrentPlayerState(player: environment.playerForPlayerType(playerType))
        return .init(value: .startObservingMusicPlayer)
    case let .playerDidQuit(playerType):
        state.availablePlayers.removeAll(where: { $0 == playerType })
        if state.currentPlayerState.currentPlayerType == playerType && state.availablePlayers.count == 0  {
            return Effect(value: .currentPlayerDidChange(nil))
        } else if state.currentPlayerState.currentPlayerType == playerType,
                  let availablePlayerType = state.availablePlayers.first {// current player quit and there is more players available
            return Effect(value: .currentPlayerDidChange(availablePlayerType))
        }
       
        return .none
    case .stopObservingPlayers:
        return .cancel(id: PlayerObservingId())
    case .startObservingMusicPlayer:
        return environment
            .musicTrackDidChange
            .map { .trackDidChange($0) }
            .cancellable(id: MusicPlayerObservingId())
    case .stopObservingMusicPlayer:
        return .cancel(id: MusicPlayerObservingId())
    case .trackDidChange(let track):
        state.currentPlayerState = CurrentPlayerState(player: environment.playerForPlayerType(state.currentPlayerState.currentPlayerType))
        if let player = environment.playerForPlayerType(state.currentPlayerState.currentPlayerType) {
            if (state.currentPlayerState.currentTrack?.coverData == nil
                || state.currentPlayerState.currentTrack?.artist ==  nil)
                && player.state == .playing {
                return Effect.timer(id: TimerId(), every: 1, on: DispatchQueue.main.eraseToAnyScheduler()).map { _ in .retryGettingArtwork }
            }
        }
        
        return .none
    case .retryGettingArtwork:
        #warning("fix")
        return Effect.concatenate(
            .cancel(id: TimerId()),
            Effect(value: .trackDidChange(environment.musicApp.currentTrack!))
        )
    }
}
