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

    func testReducer() throws {
        /// Saturday, June 26, 2021 7:47:30 PM GMT
        let date = Date(timeIntervalSince1970: 1624736850)

        let environent = SystemEnvironment(
            environment: PlayerScrobblerEnvironment(musicApp: MusicAppMock()),
            mainQueue: .immediate,
            date: { date },
            settings: MockSettings()
        )
        
        let testStore = TestStore(initialState: PlayerScrobblerState(timerState: LastFmTimerState()), reducer: playerScrobblerReducer, environment: environent)
    }

}
