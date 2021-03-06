//
//  PlayerAction.swift
//  NepTunes
//
//  Created by Adam Różyński on 31/05/2021.
//

import Foundation
import Shared
import PlayersBridge

public enum PlayerAction: Equatable {
    case appAction(PlayerAppAction)
    case trackAction(PlayerTrackAction)
}

public enum PlayerAppAction: Equatable {
    case startObservingPlayers
    case currentPlayerDidChange(PlayerType?)
    case newPlayerIsAvailable(PlayerType)
    case playerDidQuit(PlayerType)
    case stopObservingPlayers
    case startObservingPlayer(PlayerType)
    case stopObservingPlayer(PlayerType)
}

public enum PlayerTrackAction: Equatable {
    /// action sent when the Music.app sends a notification that something changed
    ///
    /// because Music.app sends a lot of trash notifications we have to handle them – thay's why there is ``newTrack`` and ``trackBasicInfoAvailable``
    case playerInfo(Track)
    
    /// after the initial verification we're sending this even so we can decide what's next
    ///
    /// for example it can have nil duration
    case newTrack(Track)
    
    /// this action is sent if the duration is available
    case trackBasicInfoAvailable(Track)
    
    /// this action is sent when the track doesn't have artworkData but has the artworkURL
    /// (it's a track from Spotify)
    case trackHasArtworkURL(Track)
    
    /// this action is sent when we can't get the artwork from the app and we have to download it
    case trackDoesNotHaveBothArtworkAndArtworkURL(Track)
    
    /// this action is sent when
    case trackArtworkIsAvailable(Track)
    
    /// this action is sent when the artwork download failed
    case provideDefaultCover(Track)
    
    case noTrack
}
