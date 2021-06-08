//
//  PlayerState.swift
//  NepTunes
//
//  Created by Adam Różyński on 01/06/2021.
//

import Foundation

struct PlayerState: Equatable {
    var availablePlayers: [PlayerType] = []
    var currentPlayerState = CurrentPlayer.none
}

enum CurrentPlayer: Equatable {
    case none
    case playerWithoutTrack(PlayerType)
    case playerWithTrack(PlayerType, Track)

    init(player: Player?) {
        if let player = player, let track = player.currentTrack {
            self = .playerWithTrack(player.type, track)
        } else if let player = player {
            self = .playerWithoutTrack(player.type)
        } else {
            self = .none
        }
    }
    
    var currentPlayerType: PlayerType? {
        switch self {
        case .none:
            return nil
        case let .playerWithTrack(player, _), let .playerWithoutTrack(player):
            return player
        }
    }
    
    var currentTrack: Track? {
        switch self {
        case let .playerWithTrack(_, track):
            return track
        default:
            return nil
        }
    }
    
}
