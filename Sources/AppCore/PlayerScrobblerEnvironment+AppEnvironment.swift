//
//  PlayerScrobblerEnvironment+AppEnvironment.swift
//  
//
//  Created by Adam Różyński on 13/07/2021.
//

import Scrobbler

extension PlayerScrobblerEnvironment {
    static func live(_ environment: AppEnvironment) -> Self {
        return Self(musicApp: environment.playerEnvironment.musicApp,
                    spotifyApp: environment.playerEnvironment.spotifyApp,
                    playerForPlayerType: environment.playerEnvironment.playerForPlayerType)
    }
}
