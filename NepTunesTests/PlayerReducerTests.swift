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
    
    func testPlayerAppReducer() throws {
        
        let newPlayerLaunched = PassthroughSubject<PlayerType, Never>()
        let playerDidQuit = PassthroughSubject<PlayerType, Never>()
        
        var runningPlayers: [PlayerType] = [.musicApp, .spotify]
        
        var currentlyRunningPlayers: () -> [PlayerType]? = {
            if runningPlayers.count > 0 {
                return runningPlayers
            } else {
                return nil
            }
        }
        
        let playerAppEnvironment = PlayerAppEnvironment(currentlyRunningPlayers: currentlyRunningPlayers,
                                                        newPlayerLaunched: newPlayerLaunched.eraseToEffect(),
                                                        playerQuit: playerDidQuit.eraseToEffect())
        
  
        
        let store = TestStore(
            initialState: PlayerState(),
            reducer: playerAppReducer,
            environment:
                SystemEnvironment(
                    environment: playerAppEnvironment,
                    mainQueue: .immediate,
                    runLoop: .immediate,
                    date: { self.date },
                    settings: MockSettings()
                )
        )
        
        store.send(.startObservingPlayers)
        store.receive(.newPlayerIsAvailable(.musicApp)) { state in
            state.availablePlayers = [.musicApp]
        }
        
        store.receive(.newPlayerIsAvailable(.spotify)) { state in
            state.availablePlayers = [.musicApp, .spotify]
        }
        
        store.receive(.currentPlayerDidChange(.musicApp)) { state in
            state.currentPlayerState = CurrentPlayerState(playerType: .musicApp, currentTrack: nil)
        }
        
        store.receive(.startObservingPlayer(.musicApp))

        
        // stop observing shit
        store.send(.stopObservingPlayers)
        
    }
    
}
