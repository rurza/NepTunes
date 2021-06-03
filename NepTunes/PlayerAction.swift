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
    case retryGettingArtwork
}

//extension PlayerAction {
//    static func == (lhs: PlayerAction, rhs: PlayerAction) -> Bool {
//        switch (lhs, rhs) {
//        case (.trackChanged(track: let lhsTrack, player: let lhsPlayer), .trackChanged(track: let rhsTrack, player: let rhsPlayer)):
//            return lhsTrack == rhsTrack && lhsPlayer.type == rhsPlayer.type
//        }
//    }
//}
