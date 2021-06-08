//
//  PlayerReducer.swift
//  NepTunes
//
//  Created by Adam Różyński on 01/06/2021.
//

import Cocoa
import ComposableArchitecture
import Combine


let playerReducer = Reducer<SharedState<PlayerState>, PlayerAction, SystemEnvironment<PlayerEnvironment>> { state, action, environment in
    
    struct PlayerObservingId: Hashable { }
    struct MusicPlayerObservingId: Hashable { }
    struct RetryGetArtworkId: Hashable { }
    struct DownloadArtworkId: Hashable { }
    
    switch action {
    case .startObservingPlayers:
        for app in NSWorkspace.shared.runningApplications {
            let playerType = PlayerType(runningApplication: app)
        }
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
        state.currentPlayerState = CurrentPlayer(player: environment.environment.playerForPlayerType(playerType))
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
    case let .trackDidChange(track):
        let effects: [Effect<PlayerAction, Never>] = [.cancel(id: RetryGetArtworkId()), .cancel(id: DownloadArtworkId())]
        if let currentPlayerType = state.currentPlayerState.currentPlayerType {
            state.currentPlayerState = .playerWithTrack(currentPlayerType, track)
            if track.artworkData == nil && state.settings.showCover {
                let getArtwork = environment.getTrackInfo
                    .map { return PlayerAction.trackDidChange($0) }
                    .catch { _ in
                        
                        return Effect<PlayerAction, Never>(value: .provideDefaultCover)
                    }
                    .eraseToEffect()
                return .concatenate(effects + [getArtwork])
            }
        }
        return .merge(effects)
    case .getCoverURL:
        return .concatenate(.cancel(id: RetryGetArtworkId()))
        
    case .getCover(_):
        return .none
    case .provideDefaultCover:
        return .none
    }
}

