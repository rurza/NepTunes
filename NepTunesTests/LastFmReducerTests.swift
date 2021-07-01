//
//  LastFmReducerTests.swift
//  NepTunesTests
//
//  Created by Adam Różyński on 01/07/2021.
//

@testable import NepTunes
import XCTest
import ComposableArchitecture
import Combine

class LastFmReducerTests: XCTestCase {
    
    func testReducer() throws {
        let date = Date(timeIntervalSince1970: 1624736850)

        let lastFmEnvironment = LastFmEnvironment(lastFmClient: .mock(with: { request in
            return Future<Data, URLError> { promise in
                promise(.success(Data()))
            }.eraseToAnyPublisher()
        }))
        
        let scheduler = DispatchQueue.test
        
        let systemEnvironment = SystemEnvironment(environment: lastFmEnvironment, mainQueue: scheduler.eraseToAnyScheduler(), date: { date }, settings: MockSettings())
        
        let store = TestStore(initialState: LastFmState(), reducer: lastFmReducer, environment: systemEnvironment)
        
        store.send(.timerAction(.start)) { state in
            state.lastFmTimerState.isTimerActive = true
        }
        
        scheduler.advance(by: 2)
        store.receive(.timerAction(.timerTicked)) { state in
            state.lastFmTimerState.secondsElapsed = 1
        }
        
        store.receive(.timerAction(.timerTicked)) { state in
            state.lastFmTimerState.secondsElapsed = 2
        }
        
        store.send(.timerAction(.pause)) { state in
            state.lastFmTimerState.secondsElapsed = 2
            state.lastFmTimerState.isTimerActive = false
        }
        
        scheduler.advance(by: 2)
        
        store.send(.timerAction(.start)) { state in
            state.lastFmTimerState.secondsElapsed = 2
            state.lastFmTimerState.isTimerActive = true
        }
        
        scheduler.advance(by: 1)
        
        store.receive(.timerAction(.timerTicked)) { state in
            state.lastFmTimerState.secondsElapsed = 3
        }
        
        store.send(.timerAction(.invalidate)) { state in
            state.lastFmTimerState.isTimerActive = false
            state.lastFmTimerState.secondsElapsed = 0
        }
        
    }
}
