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

    var mainQueue: AnySchedulerOf<DispatchQueue>
    var lastFmClient: LastFmClient
    var newPlayerLaunched: Effect<PlayerType, Never>
    var playerQuit: Effect<PlayerType, Never>
    var musicTrackDidChange: Effect<Track, Never>
    var musicApp: Player
    var date: () -> Date
    
    static let live = Self(
        mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
        lastFmClient: .live,
        newPlayerLaunched: newPlayerLaunchedEffect,
        playerQuit: playerQuitEffect,
        musicTrackDidChange: musicTrackDidChangeEffect,
        musicApp: MusicApp(),
        date: Date.init
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

private let musicTrackDidChangeEffect: Effect<Track, Never> = DistributedNotificationCenter
    .default
    .publisher(for: NSNotification.Name(rawValue: "com.apple.Music.playerInfo"))
    .compactMap {
        if let userInfo = $0.userInfo,
           let title = userInfo["Name"] as? String,
           let artist = userInfo["Artist"] as? String,
           let album = userInfo["Album"] as? String {
            return Track(title :title, artist: artist, album: album, albumArtist: nil, coverData: nil)
        }
        return nil
    }
    .eraseToEffect()
