//
//  PlayerState.swift
//  NepTunes
//
//  Created by Adam Różyński on 01/06/2021.
//

import Foundation
import Shared
import PlayersBridge

public struct PlayerState: Equatable {
    public var availablePlayers: [PlayerType] = []
    public var currentPlayerState: CurrentPlayerState?
    
    public init(availablePlayers: [PlayerType] = [], currentPlayerState: CurrentPlayerState? = nil) {
        self.availablePlayers = availablePlayers
        self.currentPlayerState = currentPlayerState
    }
    
}
