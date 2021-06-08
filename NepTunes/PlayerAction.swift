//
//  PlayerAction.swift
//  NepTunes
//
//  Created by Adam Różyński on 31/05/2021.
//

import Foundation

enum PlayerAction: Equatable {
    case startObservingPlayers
    case currentPlayerDidChange(PlayerType?)
    case newPlayerIsAvailable(PlayerType)
    case playerDidQuit(PlayerType)
    case stopObservingPlayers
    case startObservingMusicPlayer
    case stopObservingMusicPlayer
    case trackDidChange(Track)
    case getCoverURL
    case getCover(URL)
    case provideDefaultCover
}
