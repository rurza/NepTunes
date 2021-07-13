//
//  AppEnvironment.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import LastFmKit
import LastFm
import Combine
import ComposableArchitecture
import Player

public struct AppEnvironment {

    public var lastFmClient: LastFmClient
    public var playerEnvironment: PlayerEnvironment
    
    public static let live = Self(
        lastFmClient: .live,
        playerEnvironment: .live
    )
    
}

