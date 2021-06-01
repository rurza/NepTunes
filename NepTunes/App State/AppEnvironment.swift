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
    var date: () -> Date
    
    static let live = Self(
        mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
        lastFmClient: .live,
        newPlayerLaunched: newPlayerLaunchedEffect,
        playerQuit: playerQuitEffect,
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
