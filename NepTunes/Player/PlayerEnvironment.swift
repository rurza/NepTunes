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
        let track: Track?
    }
    
    var appEnvironment: PlayerAppEnvironment
    var spotifyApp: Player
    var musicApp: Player

    var artworkDownloader: ArtworkDownloader

    // Effects

    var musicTrackDidChange: Effect<Track, Never>
    var spotifyTrackDidChange: Effect<Track, Never>
    var getTrackInfo: (Player) -> Effect<Track, PlayerEnvironment.Error>
    
    var playerForPlayerType: (PlayerType) -> Player
    
}

struct PlayerAppEnvironment {
    var currentlyRunningPlayers: () -> [PlayerType]?
    var newPlayerLaunched: Effect<PlayerType, Never>
    var playerQuit: Effect<PlayerType, Never>
    
    static var live: Self {
        Self(currentlyRunningPlayers: getCurrentlyRunningPlayers,
             newPlayerLaunched: newPlayerLaunchedEffect,
             playerQuit: playerQuitEffect)
    }
}

extension PlayerEnvironment {
    static var live: Self {
        let musicApp = MusicApp()
        let spotifyApp = SpotifyApp()
        return Self(
            appEnvironment: .live,
            spotifyApp: spotifyApp,
            musicApp: musicApp,
            artworkDownloader: .live,
            musicTrackDidChange: musicTrackDidChangeEffect,
            spotifyTrackDidChange: spotifyTrackDidChangeEffect,
            getTrackInfo: getTrackInfoFromPlayerEffect,
            playerForPlayerType: playerForPlayerTypeWithAvailablePlayers(musicApp, spotifyApp))
    }
}


private let newPlayerLaunchedEffect = NSWorkspace.shared
    .notificationCenter
    .publisher(for: NSWorkspace.didLaunchApplicationNotification)
    .compactMap {  note -> PlayerType? in
        let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        return PlayerType(runningApplication: app)
    }
    .eraseToEffect()

private let playerQuitEffect = NSWorkspace.shared
    .notificationCenter
    .publisher(for: NSWorkspace.didTerminateApplicationNotification)
    .compactMap {  note -> PlayerType? in
        let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
        return PlayerType(runningApplication: app)
    }
    .eraseToEffect()

private let musicTrackDidChangeEffect: Effect<Track, Never>
    = DistributedNotificationCenter
    .default
    .publisher(for: NSNotification.Name(rawValue: "com.apple.Music.playerInfo"))
    .compactMap { Track(userInfo: $0.userInfo) }
    .eraseToEffect()

private let spotifyTrackDidChangeEffect: Effect<Track, Never>
    = DistributedNotificationCenter
    .default
    .publisher(for: NSNotification.Name(rawValue: "com.spotify.client.PlaybackStateChanged"))
    .compactMap {
        print("🧑‍🎤 \($0.userInfo)")
        return Track(userInfo: $0.userInfo) }
    .eraseToEffect()


private let getTrackInfoFromPlayerEffect: (Player) -> Effect<Track, PlayerEnvironment.Error> = { player in
    Effect<Track, PlayerEnvironment.Error>
        .run { subscriber in
            guard player.isRunning else {
                return AnyCancellable { }
            }
            if let track = player.currentTrack {
                if track.duration == nil {
                    subscriber.send(completion: .failure(PlayerEnvironment.Error(type: .noDuration, track: track)))
                } else if track.artworkData == nil && track.artworkURL == nil {
                    subscriber.send(completion: .failure(PlayerEnvironment.Error(type: .noCover, track: track)))
                } else {
                    subscriber.send(track)
                    subscriber.send(completion: .finished)
                }
            } else {
                subscriber.send(completion: .failure(PlayerEnvironment.Error(type: .noTrack, track: nil)))
            }
            return AnyCancellable { }
        }.eraseToEffect()
}

private let getCurrentlyRunningPlayers: () -> [PlayerType]? = {
    var playerTypes = [PlayerType]()
    for app in NSWorkspace.shared.runningApplications {
        if let playerType = PlayerType(runningApplication: app) {
            playerTypes.append(playerType)
        }
    }
    if playerTypes.count > 0 {
        return playerTypes
    } else {
        return nil
    }
}

private let playerForPlayerTypeWithAvailablePlayers: (MusicApp, SpotifyApp) -> (PlayerType) -> Player
    = { musicApp, spotifyApp in
        { playerType in
            switch playerType {
            case .musicApp:
                return musicApp
            case .spotify:
                return spotifyApp
            }
        }
    }
