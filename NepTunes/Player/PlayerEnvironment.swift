//
//  PlayerEnvironment.swift
//  NepTunes
//
//  Created by Adam Różyński on 01/06/2021.
//

import Cocoa
import ComposableArchitecture
import Combine
import DeezerClient

struct PlayerEnvironment {
    
    struct Error: Swift.Error {
        enum `Type` {
            case noCover
            case noDuration
            case noTrack
        }
        let type: Type
        let track: Track
    }
    
    var newPlayerLaunched: Effect<PlayerType, Never>
    var playerQuit: Effect<PlayerType, Never>
    var musicTrackDidChange: Effect<Track, Never>
    var musicApp: Player
    var getTrackInfo: Effect<Track, PlayerEnvironment.Error>
    var artworkDownloader: ArtworkDownloader
    var currentlyRunningPlayer: () -> PlayerType?
    
}

extension PlayerEnvironment {
    static func live(appEnvironment: AppEnvironment) -> Self {
        return Self(newPlayerLaunched: appEnvironment.newPlayerLaunched,
                    playerQuit: appEnvironment.playerQuit,
                    musicTrackDidChange: appEnvironment.musicTrackDidChange,
                    musicApp: appEnvironment.musicApp,
                    getTrackInfo: getTrackInfoFromPlayer(appEnvironment.musicApp),
                    artworkDownloader: appEnvironment.artworkDownloader,
                    currentlyRunningPlayer: getCurrentlyRunningPlayer)
    }
}


private let getTrackInfoFromPlayer: (Player) -> Effect<Track, PlayerEnvironment.Error> = { player in
    Effect<Track, PlayerEnvironment.Error>
        .run { subscriber in
            if let track = player.currentTrack {
                if track.duration == nil {
                    subscriber.send(completion: .failure(PlayerEnvironment.Error(type: .noDuration, track: track)))
                } else if track.artworkData == nil {
                    subscriber.send(completion: .failure(PlayerEnvironment.Error(type: .noCover, track: track)))
                } else {
                    subscriber.send(track)
                    subscriber.send(completion: .finished)
                }
            } else {
                subscriber.send(completion: .failure(PlayerEnvironment.Error(type: .noTrack, track: .emptyTrack)))
            }
            return AnyCancellable { }
        }.eraseToEffect()
}

private let getCurrentlyRunningPlayer: () -> PlayerType? = {
    for app in NSWorkspace.shared.runningApplications {
        if let playerType = PlayerType(runningApplication: app) {
            return playerType
        }
    }
    return nil
}
