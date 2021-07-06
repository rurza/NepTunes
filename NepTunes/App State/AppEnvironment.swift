//
//  AppEnvironment.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import Cocoa
import LastFmKit
import Combine
import ComposableArchitecture

struct AppEnvironment {

    var lastFmClient: LastFmClient
    var newPlayerLaunched: Effect<PlayerType, Never>
    var playerQuit: Effect<PlayerType, Never>
    var musicTrackDidChange: Effect<Track, Never>
    var spotifyTrackDidChange: Effect<Track, Never>
    var artworkDownloader: ArtworkDownloader
    var musicApp: Player
    var spotifyApp: Player
    
    static let live = Self(
        lastFmClient: .live,
        newPlayerLaunched: newPlayerLaunchedEffect,
        playerQuit: playerQuitEffect,
        musicTrackDidChange: musicTrackDidChangeEffect,
        spotifyTrackDidChange: spotifyTrackDidChangeEffect,
        artworkDownloader: .live,
        musicApp: MusicApp(),
        spotifyApp: SpotifyApp()
    )
    
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
    .compactMap { Track(userInfo: $0.userInfo) }
    .eraseToEffect()
