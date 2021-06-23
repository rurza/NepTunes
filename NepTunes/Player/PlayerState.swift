//
//  PlayerState.swift
//  NepTunes
//
//  Created by Adam Różyński on 01/06/2021.
//

import Foundation

struct PlayerState: Equatable {
    var availablePlayers: [PlayerType] = []
    var currentPlayerState: CurrentPlayerState?
}

struct CurrentPlayerState: Equatable {
    let playerType: PlayerType
    var currentTrack: Track?
}
