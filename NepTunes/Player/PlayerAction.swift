//
//  PlayerAction.swift
//  NepTunes
//
//  Created by Adam Różyński on 31/05/2021.
//

import Foundation

enum PlayerAction: Equatable {
    case appAction(PlayerAppAction)
    case trackAction(PlayerTrackAction)
}

enum PlayerAppAction: Equatable {
    case startObservingPlayers
    case currentPlayerDidChange(PlayerType?)
    case newPlayerIsAvailable(PlayerType)
    case playerDidQuit(PlayerType)
    case stopObservingPlayers
    case startObservingPlayer(PlayerType)
    case stopObservingPlayer(PlayerType)
}

enum PlayerTrackAction: Equatable {
    case trackDidChange(Track)
    case provideDefaultCover
}
