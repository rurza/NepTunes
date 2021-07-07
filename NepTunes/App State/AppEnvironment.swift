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
    var playerEnvironment: PlayerEnvironment
    
    static let live = Self(
        lastFmClient: .live,
        playerEnvironment: .live
    )
    
}

