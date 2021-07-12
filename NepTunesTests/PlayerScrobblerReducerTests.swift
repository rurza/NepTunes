//
//  PlayerScrobblerReducerTests.swift
//  NepTunesTests
//
//  Created by Adam Różyński on 01/07/2021.
//

import XCTest
import Combine
import ComposableArchitecture
@testable import NepTunes

class PlayerScrobblerReducerTests: XCTestCase {

    func testTimerTickedAction() throws {
        /// Saturday, June 26, 2021 7:47:30 PM GMT
        var date = Date(timeIntervalSince1970: 1624736850)

        var musicApp = MusicAppMock()
        
        let spotify = SpotifyMock()
        
        let playerScrobblerEnvironment = PlayerScrobblerEnvironment(musicApp: musicApp, spotifyApp: spotify) { playerType in
            switch playerType {
            case .musicApp:
                return musicApp
            case .spotify:
                return spotify
            }
        }
        
        let environment = SystemEnvironment(
            environment: playerScrobblerEnvironment,
            mainQueue: .immediate,
            runLoop: .immediate,
            date: { date },
            settings: MockSettings()
        )
        
        let trackDuration: TimeInterval = 200

        let track = Track(title: "Ágćtis Byrjun",
                          artist: "Sigur Rós",
                          album: "Heim",
                          albumArtist: "Sigur Rós",
                          artworkData: nil,
                          artworkURL: nil,
                          duration: trackDuration)!

        let state = PlayerScrobblerState(currentPlayerState: CurrentPlayerState(playerType: .musicApp, currentTrack: track))
        let testStore = TestStore(initialState: state,
                                  reducer: playerScrobblerReducer,
                                  environment: environment)
        
        musicApp.state = .playing
        
        testStore.send(.newTrack(track))
        testStore.receive(.timerAction(.invalidate))
        
        testStore.send(.trackBasicInfoAvailable(track))
        testStore.receive(.timerAction(.start(fireInterval: trackDuration / 2)))
        
        testStore.send(.playerInfo(track))
        testStore.receive(.timerAction(.toggle))
    }
    
//    func testPlayerInfoAction() throws {
//        /// Saturday, June 26, 2021 7:47:30 PM GMT
//        let date = Date(timeIntervalSince1970: 1624736850)
//
//        let musicApp = MusicAppMock()
//
//        let environment = SystemEnvironment(
//            environment: PlayerScrobblerEnvironment(musicApp: musicApp),
//            mainQueue: .immediate,
//            date: { date },
//            settings: MockSettings()
//        )
//
//        var testStore = TestStore(initialState: PlayerScrobblerState(),
//                                  reducer: playerScrobblerReducer,
//                                  environment: environment)
//        let track = Track(title: "Ágćtis Byrjun",
//                          artist: "Sigur Rós",
//                          album: "Heim",
//                          albumArtist: "Sigur Rós",
//                          artworkData: nil,
//                          duration: 396)
//
//        // the reducer checks the environment for the state of the music app
//        // if the music app isn't playing and this track isn't the same track that
//        // currently is playing this action will send invalidate
//        testStore.send(.playerInfo(track))
//
//        // we invalidate existing timer so we expect to receive `.timerAction(.invalidate)`
//        testStore.receive(.timerAction(.invalidate)) { state in
//            state.timerState.isTimerActive = false
//            state.timerState.secondsElapsed = 0
//        }
//
//        // we're sending again playerInfo but now with different musicApp playback state
//        // this shouldn't change the state at all and it shouldn't send any action
//        musicApp.state = .playing
//        testStore.send(.playerInfo(track)) { state in
//            state.timerState.isTimerActive = false
//            state.timerState.secondsElapsed = 0
//        }
//
//        // now we want to mock the situation where we received .playerInfo
//        // and the track is the same as the track in the state
//        // in Music.app it means that the user toggled the playback – we want to start the timer
//        //
//        // the problem is that in real life the state will be changed by the completely different reducer
//        // as the PlayerScrobblerState is derived from a parent state
//        // that's why we have to create the new store
//        musicApp.state = .playing
//        let secondsElapsed = 12
//        let pausedTimerState = LastFmTimerState(isTimerActive: false, secondsElapsed: secondsElapsed)
//        testStore = TestStore(initialState: PlayerScrobblerState(currentTrack: track, timerState: pausedTimerState),
//                              reducer: playerScrobblerReducer,
//                              environment: environment)
//        // the state already has a currentTrack
//        // the player state is playing (the user already pressed the button)
//        // the timer is paused with some seconds elapsed already set
//        testStore.send(.playerInfo(track))
//        testStore.receive(.timerAction(.start)) { state in
//            state.currentTrack = track
//            // we don't deal with the timer state in the playerScrobblerReducer
//            state.timerState.isTimerActive = false
//            state.timerState.secondsElapsed = secondsElapsed
//        }
//
//    }

}
