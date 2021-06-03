//
//  PlayerEnvironment.swift
//  NepTunes
//
//  Created by Adam Różyński on 01/06/2021.
//

import Foundation
import ComposableArchitecture

struct PlayerEnvironment {
    var newPlayerLaunched: Effect<PlayerType, Never>
    var playerQuit: Effect<PlayerType, Never>
    var musicTrackDidChange: Effect<Track, Never>
    var musicApp: Player
    
    func playerForPlayerType(_ playerType: PlayerType?) -> Player? {
        switch playerType {
        case .musicApp:
            return musicApp
        case .none:
            return nil
        default:
            fatalError()
        }
    }
}
