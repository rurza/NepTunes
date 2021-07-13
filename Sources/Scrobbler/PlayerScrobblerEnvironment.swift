//
//  PlayerScrobblerEnvironment.swift
//  NepTunes
//
//  Created by Adam Różyński on 02/07/2021.
//

import Foundation
import Shared

public struct PlayerScrobblerEnvironment {
    public var musicApp: Player
    public var spotifyApp: Player
    
    public var playerForPlayerType: (PlayerType) -> Player
    
    public init(musicApp: Player, spotifyApp: Player, playerForPlayerType: @escaping (PlayerType) -> Player) {
        self.musicApp = musicApp
        self.spotifyApp = spotifyApp
        self.playerForPlayerType = playerForPlayerType
    }
}
