//
//  AppEnvironment.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import LastFm
import Combine
import ComposableArchitecture
import Player

public struct AppEnvironment {

    public var lastFmEnvironment: LastFmEnvironment
    public var playerEnvironment: PlayerEnvironment
    
    public static let live = Self(
        lastFmEnvironment: .live,
        playerEnvironment: .live
    )
    
}

