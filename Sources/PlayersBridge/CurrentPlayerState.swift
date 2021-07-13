//
//  CurrentPlayerState.swift
//  
//
//  Created by Adam Różyński on 13/07/2021.
//

import Shared

public struct CurrentPlayerState: Equatable {

    public let playerType: PlayerType
    public var currentTrack: Track?
    
    public init(playerType: PlayerType, currentTrack: Track? = nil) {
        self.playerType = playerType
        self.currentTrack = currentTrack
    }
    
}
