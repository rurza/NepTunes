//
//  PlayerEnvironment.swift
//  NepTunes
//
//  Created by Adam Różyński on 01/06/2021.
//

import Foundation
import ComposableArchitecture
import Combine
import DeezerClient

struct PlayerEnvironment {
    
    enum NoInfoError: Error {
        case noCover
    }
    
    var newPlayerLaunched: Effect<PlayerType, Never>
    var playerQuit: Effect<PlayerType, Never>
    var musicTrackDidChange: Effect<Track, Never>
    var musicApp: Player
    var getTrackInfo: Effect<Track, NoInfoError>
    var artworkDownloader: ArtworkDownloader
    
    func playerForPlayerType(_ playerType: PlayerType?) -> Player? {
        switch playerType {
        case .musicApp:
            return musicApp
        case .none:
            return nil
        default:
            fatalError()
        }
    }
    
}

var getTrackCoverFromPlayer: (Player) -> Effect<Track, PlayerEnvironment.NoInfoError> = { player in
    Effect<Track, PlayerEnvironment.NoInfoError>
        .run { subscriber in
            print("🙈 getting track Info")
            if let track = player.currentTrack {
                if track.artworkData == nil {
                    print("🙉 retrying")
                    subscriber.send(completion: .failure(.noCover))
                } else {
                    subscriber.send(track)
                    subscriber.send(completion: .finished)
                }
            }
            return AnyCancellable { }
        }.eraseToEffect()
}
