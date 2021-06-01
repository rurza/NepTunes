//
//  PlayerState.swift
//  NepTunes
//
//  Created by Adam Różyński on 01/06/2021.
//

import Foundation

struct PlayerState: Equatable {
    var availablePlayers: [PlayerType] = []
    var currentPlayer: PlayerType?
}
