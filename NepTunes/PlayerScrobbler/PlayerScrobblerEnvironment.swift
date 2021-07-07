//
//  PlayerScrobblerEnvironment.swift
//  NepTunes
//
//  Created by Adam Różyński on 02/07/2021.
//

import Foundation

struct PlayerScrobblerEnvironment {
    var musicApp: Player
    var spotifyApp: Player
    
    var playerForPlayerType: (PlayerType) -> Player

    
    static func live(_ environment: AppEnvironment) -> Self {
        return Self(musicApp: environment.playerEnvironment.musicApp,
                    spotifyApp: environment.playerEnvironment.spotifyApp,
                    playerForPlayerType: environment.playerEnvironment.playerForPlayerType)
    }
}
