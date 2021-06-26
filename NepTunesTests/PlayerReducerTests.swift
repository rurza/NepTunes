//
//  PlayerReducerTests.swift
//  PlayerReducerTests
//
//  Created by Adam Różyński on 28/04/2021.
//

import XCTest
import ComposableArchitecture
import Combine
@testable import NepTunes

class PlayerReducerTests: XCTestCase {
    
    /// Saturday, June 26, 2021 7:47:30 PM GMT
    let date = Date(timeIntervalSince1970: 1624736850)
    
    func testReducer() throws {

        let playerType = PlayerType.musicApp
        
        let musicTrackDidChange = PassthroughSubject<Track, Never>()
        
        let newTrack = Track(title: "Ágćtis Byrjun",
                             artist: "Sigur Rós",
                             album: "Heim",
                             albumArtist: "Sigur Rós",
                             artworkData: nil,
                             duration: 396)
        
        let getTrackArtwork = Effect<Track, PlayerEnvironment.Error>(error: PlayerEnvironment.Error.noCover)
        
        // artwork data used for the ArtworkDownloader
        let artworkData = Data()
        
        let playerEnvironment = PlayerEnvironment(newPlayerLaunched: .none,
                                                  playerQuit: .none,
                                                  musicTrackDidChange: musicTrackDidChange.eraseToEffect(),
                                                  musicApp: MusicAppMock(),
                                                  getTrackInfo: getTrackArtwork,
                                                  artworkDownloader: .mock(data: { artworkData }),
                                                  currentlyRunningPlayer: {
                                                    playerType
                                                  })
        
        let store = TestStore(
            initialState: PlayerState(),
            reducer: playerReducer,
            environment:
                SystemEnvironment(
                    environment: playerEnvironment,
                    mainQueue: .immediate,
                    date: { self.date },
                    settings: MockSettings()
                )
        )
        
        store.send(.appAction(.startObservingPlayers))
        store.receive(.appAction(.newPlayerIsAvailable(playerType))) { state in
            state.availablePlayers = [playerType]
        }
        store.receive(.appAction(.currentPlayerDidChange(playerType))) { state in
            state.currentPlayerState = CurrentPlayerState(playerType: playerType, currentTrack: nil)
        }
        store.receive(.appAction(.startObservingPlayer(.musicApp)))

        
        store.send(.trackAction(.trackDidChange(newTrack))) { state in
            state.currentPlayerState?.currentTrack = newTrack
        }
        
        var trackWithEmptyArtworkData = newTrack
        trackWithEmptyArtworkData.artworkData = artworkData
        
        store.receive(.trackAction(.trackDidChange(trackWithEmptyArtworkData))) { state in
            state.currentPlayerState?.currentTrack = trackWithEmptyArtworkData
        }
        
        store.send(.appAction(.newPlayerIsAvailable(.spotify))) { state in
            state.availablePlayers = [.musicApp, .spotify]
            state.currentPlayerState = CurrentPlayerState(playerType: .musicApp, currentTrack: trackWithEmptyArtworkData)
        }
        
        store.send(.appAction(.playerDidQuit(.musicApp))) { state in
            state.availablePlayers = [.spotify]
        }
        
        store.receive(.appAction(.stopObservingPlayer(.musicApp)))
        
        store.receive(.appAction(.currentPlayerDidChange(.spotify))) { state in
            state.currentPlayerState = CurrentPlayerState(playerType: .spotify, currentTrack: nil)
        }
        
        store.receive(.appAction(.startObservingPlayer(.spotify)))
        
        // stop observing shit
        store.send(.appAction(.stopObservingPlayers))
        store.send(.appAction(.stopObservingPlayer(.spotify)))
        
    }
    
}
