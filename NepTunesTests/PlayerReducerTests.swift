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
        
        let getTrackArtwork = Effect<Track, PlayerEnvironment.Error>(error: PlayerEnvironment.Error(type: .noDuration, track: .emptyTrack))
        
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

        
        store.send(.trackAction(.playerInfo(.emptyTrack))) { state in
            state.currentPlayerState?.currentTrack = nil
        }
        
        // 1. we received new info about the track
        store.send(.trackAction(.playerInfo(newTrack)))
        
        // 2. the track is new, so we'll receive .newTrack action
        store.receive(.trackAction(.newTrack(newTrack)))
        
        // 3. the track has duration, so we'll receive .trackBasicInfoAvailable and the state will change
        store.receive(.trackAction(.trackBasicInfoAvailable(newTrack))) { state in
            state.currentPlayerState?.currentTrack = newTrack
        }
        
        // 4. but the track doesn't have the artwork data, so we'll try to get the cover using `artworkDownloader`
        store.receive(.trackAction(.trackCoverNeedsToBeDownloaded(newTrack)))
        
        // 5. the artwork downloader will provide `artworkData` for the track, so our reducer will return effect with
        // `trackBasicInfoAvailable` but with the data
        var trackWithData = newTrack
        trackWithData.artworkData = artworkData
        
        // 6. and the state will change, where we have the full info about the track
        store.receive(.trackAction(.trackBasicInfoAvailable(trackWithData))) { state in
            state.currentPlayerState?.currentTrack = trackWithData
        }
        
        store.send(.appAction(.newPlayerIsAvailable(.spotify))) { state in
            state.availablePlayers = [.musicApp, .spotify]
            state.currentPlayerState = CurrentPlayerState(playerType: .musicApp, currentTrack: trackWithData)
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
