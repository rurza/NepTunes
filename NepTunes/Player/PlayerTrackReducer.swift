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
    // we received notification from the app, but don't know if its actually the same track
    // that's is playing right now or that the music app send some garbage notification (like "Connecting...")
    case let .playerInfo(track):
        let previousTrack = state.currentPlayerState?.currentTrack
        if track.artist == "" { // garbage from Music.app or the ad from Spotify
            // we actually want to set the current track to nil here,
            // for example the Music.app
            state.currentPlayerState?.currentTrack = nil
            return .none
            
            // the playback state changed, we don't want to do antyhing
        } else if track.isTheSameTrackAs(previousTrack) {
            return .none
            
            // actually something changed – we want to cancel all currently running effects
            // and notify the reducer that the track changed
        } else {
            return .merge(
                .cancel(id: RetryGetTrackDurationId()),
                .cancel(id: RetryGetArtworkId()),
                .cancel(id: DownloadArtworkId()),
                Effect(value: .newTrack(track))
            )
        }
        
        // the track changed but maybe we don't have all the required data
    case let .newTrack(track):
        guard let playerType = state.currentPlayerState?.playerType else { return .none }
        // if we don't have the duration – we want to get it
        if track.duration == nil {
            let player = environment.environment.playerForPlayerType(playerType)
            return environment.getTrackInfo(player)
                .cancellable(id: RetryGetTrackDurationId())
                .retry(2, delay: 1, scheduler: environment.mainQueue)
                .map { track -> PlayerTrackAction in .trackBasicInfoAvailable(track) }
                .catch { _ in Effect(value: .noTrack) }
                .eraseToEffect()
        } else {
            return Effect(value: .trackBasicInfoAvailable(track))
        }
        
        // we should have the duration
    case let .trackBasicInfoAvailable(track):
        state.currentPlayerState?.currentTrack = track
        
        // there is no artwork – we should get it from the player or download it
        if track.artworkURL != nil && track.artworkData == nil {
            return Effect(value: .trackHasArtworkURL(track))
        } else if track.artworkData == nil {
            return Effect(value: .trackDoesNotHaveBothArtworkAndArtworkURL(track))
        } else {
            return .none
        }
    case let .trackHasArtworkURL(track):
        guard let url = track.artworkURL else { fatalError() }
        return environment.artworkDownloader
            .getArtwork(url)
            .cancellable(id: DownloadArtworkId())
            .receive(on: environment.mainQueue)
            .map { data -> PlayerTrackAction in
                var track = track
                track.artworkData = data
                return .trackArtworkIsAvailable(track)
            }
            .replaceError(with: .provideDefaultCover(track))
            .eraseToEffect()
    case let .trackDoesNotHaveBothArtworkAndArtworkURL(track):
        guard let playerType = state.currentPlayerState?.playerType else { return .none }
        return environment.getTrackInfo(environment.environment.playerForPlayerType(playerType))
            .cancellable(id: RetryGetArtworkId())
            .map { .newTrack($0) }
            .catch { _ -> Effect<PlayerTrackAction, Never> in
                if let album = track.album {
                    return environment.artworkDownloader
                        .getArtworkForAlbumAndArtist(album, track.artist)
                        .cancellable(id: DownloadArtworkId())
                        .receive(on: environment.mainQueue)
                        .map { data -> PlayerTrackAction in
                            var track = track
                            track.artworkData = data
                            return .trackArtworkIsAvailable(track)
                        }
                        .catch { error in
                            return Effect(value: .provideDefaultCover(track))
                        }
                        .eraseToEffect()
                } else {
                    return Effect(value: .provideDefaultCover(track))
                }
            }
            .eraseToEffect()
    case let .trackArtworkIsAvailable(track):
        state.currentPlayerState?.currentTrack = track
        return .none
    case let .provideDefaultCover(track):
        var track = track
        #warning("handle")
        track.artworkData = Data()
        return Effect(value: .trackArtworkIsAvailable(track))
    case .noTrack:
        return .none
    }
}
.debugActions("\(Date()) 🎧")
