//
//  PlayerStateTests.swift
//  PlayerStateTests
//
//  Created by Adam Różyński on 28/04/2021.
//

import XCTest
import ComposableArchitecture
import Combine
@testable import NepTunes

class PlayerStateTests: XCTestCase {
    
    func testReducer() {
        let appLaunched = PassthroughSubject<PlayerType, Never>()
        let appQuit = PassthroughSubject<PlayerType, Never>()

        
        let store = TestStore(
            initialState: PlayerState(),
            reducer: playerReducer,
            environment: PlayerEnvironment(newPlayerLaunched: Effect(appLaunched),
                                           playerQuitEffect: Effect(appQuit))
        )
        
        store.send(.startObservingPlayers)
        
        /// 1. -> Music
        appLaunched.send(.musicApp)
        store.receive(.newPlayerIsAvailable(.musicApp)) {
            $0.availablePlayers = [.musicApp]
            $0.currentPlayer = .musicApp
        }
        
        /// 2. -> Spotify
        appLaunched.send(.spotify)
        store.receive(.newPlayerIsAvailable(.spotify)) {
            $0.availablePlayers = [.musicApp, .spotify]
            $0.currentPlayer = .musicApp
        }
        
        
        store.send(.currentPlayerDidChange(.spotify)) {
            $0.currentPlayer = .spotify
            $0.availablePlayers = [.musicApp, .spotify]
        }
        
        /// 3. Music ->
        appQuit.send(.musicApp)
        store.receive(.playerDidQuit(.musicApp)) {
            $0.availablePlayers = [.spotify]
            $0.currentPlayer = .spotify
        }
        
        appQuit.send(.spotify)
        store.receive(.playerDidQuit(.spotify)) {
            $0.availablePlayers = []
            $0.currentPlayer = nil
        }
        
        store.send(.stopObservingPlayers)
        
        appLaunched.send(.spotify)
    }
    
   
}
