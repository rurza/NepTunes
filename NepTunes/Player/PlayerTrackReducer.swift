//
//  PlayerTrackReducer.swift
//  NepTunes
//
//  Created by Adam Różyński on 23/06/2021.
//

import ComposableArchitecture


let playerTrackReducer = Reducer<PlayerState, PlayerTrackAction, SystemEnvironment<PlayerEnvironment>> { state, action, environment in
    
    struct RetryGetArtworkId: Hashable { }
    struct DownloadArtworkId: Hashable { }
    
    switch action {
    case let .trackDidChange(track):
        let previousTrack = state.currentPlayerState?.currentTrack
        state.currentPlayerState?.currentTrack = track

        let effects: [Effect<PlayerTrackAction, Never>] = [.cancel(id: RetryGetArtworkId()), .cancel(id: DownloadArtworkId())]
        if previousTrack == track { // we don't want to cancel getting artwork if it's the same track
            return .none
        }
        // if it's not the same track we want to check if we have a cover and if not we want to get one
        if track.artworkData == nil && environment.settings.showCover {
            return .concatenate(effects + [Effect(value: .currentTrackWasUpdated(track))])
        }
        // otherwise we want to cancel existing effects
        return .merge(effects)
    case let .currentTrackWasUpdated(track):
        state.currentPlayerState?.currentTrack = track
        if track.artworkData == nil && environment.settings.showCover {
            let getArtwork = environment.getTrackInfo.cancellable(id: RetryGetArtworkId())
                .map { return .currentTrackWasUpdated($0) }
                .retry(2, delay: 2, scheduler: environment.mainQueue)
                .catch { _ -> Effect<PlayerTrackAction, Never> in
                    if let album = track.album {
                        return environment.artworkDownloader
                            .getArtworkURL(album)
                            .cancellable(id: DownloadArtworkId())
                            .receive(on: environment.mainQueue)
                            .map { data -> Track in
                                var track = track
                                track.artworkData = data
                                return track
                            }
                            .map { .currentTrackWasUpdated($0) }
                            .replaceError(with: .provideDefaultCover)
                            .eraseToEffect()
                    } else {
                        return Effect(value: .provideDefaultCover)
                    }
                }
                .eraseToEffect()
            return getArtwork
        }
        return .none

    case .provideDefaultCover:
        #warning("handle")
        return .none
    }
}
