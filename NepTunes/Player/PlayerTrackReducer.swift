//
//  PlayerTrackReducer.swift
//  NepTunes
//
//  Created by Adam Różyński on 23/06/2021.
//

import ComposableArchitecture


let playerTrackReducer = Reducer<SharedState<PlayerState>, PlayerTrackAction, SystemEnvironment<PlayerEnvironment>> { state, action, environment in
    
    struct RetryGetArtworkId: Hashable { }
    struct DownloadArtworkId: Hashable { }
    
    switch action {
    case let .trackDidChange(track):
        let effects: [Effect<PlayerTrackAction, Never>] = [.cancel(id: RetryGetArtworkId()), .cancel(id: DownloadArtworkId())]
        state.currentPlayerState?.currentTrack = track
        if track.artworkData == nil && state.settings.showCover {
            let getArtwork = environment.getTrackInfo
                .map { return .trackDidChange($0) }
                .retry(2, delay: 2, scheduler: DispatchQueue.main)
                .catch { _ -> Effect<PlayerTrackAction, Never> in
                    if let album = track.album {
                        return environment.artworkDownloader.getArtworkURL(album)
                            .receive(on: DispatchQueue.main)
                            .map { data -> Track in
                                var track = track
                                track.artworkData = data
                                return track
                            }
                            .map { .trackDidChange($0) }
                            .replaceError(with: .provideDefaultCover)
                            .eraseToEffect()
                    } else {
                        return Effect(value: .provideDefaultCover)
                    }
                }
                .eraseToEffect()
            return .concatenate(effects + [getArtwork])
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
