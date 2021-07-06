//
//  PlayerTrackReducer.swift
//  NepTunes
//
//  Created by Adam Różyński on 23/06/2021.
//

import ComposableArchitecture


let playerTrackReducer = Reducer<PlayerState, PlayerTrackAction, SystemEnvironment<PlayerEnvironment>> { state, action, environment in
    
    struct RetryGetTrackDurationId: Hashable { }
    struct RetryGetArtworkId: Hashable { }
    struct DownloadArtworkId: Hashable { }
    
    switch action {
    /// we received notification from the app, but don't know if its actually the same track
    /// that's is playing right now or that the music app send some garbage notification (like "Connecting...")
    case let .playerInfo(track):
        let previousTrack = state.currentPlayerState?.currentTrack
        #warning("SUPPORT ADS FROM SPOTIFY")
        if track == Track.emptyTrack { // garbage from Music.app
            /// we actually want to set the current track to nil
            state.currentPlayerState?.currentTrack = nil
            return .none
            
            /// the playback state changed, we don't want to do antyhing
        } else if track.isTheSameTrackAs(previousTrack) {
            return .none
            
            /// actually something changed – we want to cancel all currently running effects
            /// and notify the reducer that the track changed
        } else {
            return .merge(
                .cancel(id: RetryGetTrackDurationId()),
                .cancel(id: RetryGetArtworkId()),
                .cancel(id: DownloadArtworkId()),
                Effect(value: .newTrack(track))
            )
        }
        
        /// the track changed but maybe we don't have all the required data
    case let .newTrack(track):
        
        /// if we don't have the duration – we want to get it
        if track.duration == nil {
            #warning("FIX")
            return environment.getSpotifyTrackInfo
                .cancellable(id: RetryGetTrackDurationId())
                .retry(2, delay: 1, scheduler: environment.mainQueue)
                .catch { error in
                    return Effect(value: error.track)
                }
                .eraseToEffect()
                .map { track -> PlayerTrackAction in .trackBasicInfoAvailable(track) }
        } else {
            return Effect(value: .trackBasicInfoAvailable(track))
        }
        
        /// we should have the duration
    case let .trackBasicInfoAvailable(track):
        state.currentPlayerState?.currentTrack = track
        
        /// there is no artwork – we should get it from the player or download it
        if track.artworkData == nil {
            return Effect(value: .trackCoverNeedsToBeDownloaded(track))
        } else {
            return .none
        }
    case let .trackCoverNeedsToBeDownloaded(track):
        return environment.getSpotifyTrackInfo
            .cancellable(id: RetryGetArtworkId())
            .map { .newTrack($0) }
            .catch { _ -> Effect<PlayerTrackAction, Never> in
                if let album = track.album {
                    return environment.artworkDownloader
                        .getArtworkURL(album, track.artist)
                        .cancellable(id: DownloadArtworkId())
                        .receive(on: environment.mainQueue)
                        .map { data -> Track in
                            var track = track
                            track.artworkData = data
                            return track
                        }
                        .catch { error in
                            return Effect(value: track)
                        }
                        .map { .trackBasicInfoAvailable($0) }
                        
                        .eraseToEffect()
                } else {
                    return Effect(value: .provideDefaultCover(track))
                }
            }
            .eraseToEffect()
        
    case let .provideDefaultCover(track):
        var track = track
        #warning("handle")
        track.artworkData = Data()
        return Effect(value: .newTrack(track))
    }
}
.debugActions("🎧")
