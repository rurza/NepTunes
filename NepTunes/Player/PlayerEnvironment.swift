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
    
    enum Error: Swift.Error {
        case noCover
    }
    
    var newPlayerLaunched: Effect<PlayerType, Never>
    var playerQuit: Effect<PlayerType, Never>
    var musicTrackDidChange: Effect<Track, Never>
    var musicApp: Player
    var getTrackInfo: Effect<Track, PlayerEnvironment.Error>
    var artworkDownloader: ArtworkDownloader
    var currentlyRunningPlayer: () -> PlayerType?
    
//    func playerForPlayerType(_ playerType: PlayerType?) -> Player? {
//        switch playerType {
//        case .musicApp:
//            return musicApp
//        case .none:
//            return nil
//        default:
//            fatalError()
//        }
//    }
    
}

extension PlayerEnvironment {
    static func live(appEnvironment: AppEnvironment) -> Self {
        return Self(newPlayerLaunched: appEnvironment.newPlayerLaunched,
                    playerQuit: appEnvironment.playerQuit,
                    musicTrackDidChange: appEnvironment.musicTrackDidChange,
                    musicApp: appEnvironment.musicApp,
                    getTrackInfo: getTrackCoverFromPlayer(appEnvironment.musicApp),
                    artworkDownloader: appEnvironment.artworkDownloader,
                    currentlyRunningPlayer: getCurrentlyRunningPlayer)
    }
}


private let getTrackCoverFromPlayer: (Player) -> Effect<Track, PlayerEnvironment.Error> = { player in
    Effect<Track, PlayerEnvironment.Error>
        .run { subscriber in
            if let track = player.currentTrack {
                if track.artworkData == nil {
                    subscriber.send(completion: .failure(.noCover))
                } else {
                    subscriber.send(track)
                    subscriber.send(completion: .finished)
                }
            } else {
                fatalError()
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
