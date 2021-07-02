//
//  LastFmTimerReducerTests.swift
//  NepTunesTests
//
//  Created by Adam Różyński on 01/07/2021.
//

@testable import NepTunes
import XCTest
import ComposableArchitecture
import Combine

class LastFmTimerReducerTests: XCTestCase {
    
    func testReducer() throws {
        let date = Date(timeIntervalSince1970: 1624736850)

        let lastFmEnvironment = LastFmEnvironment(lastFmClient: .mock(with: { request in
            return Future<Data, URLError> { promise in
                promise(.success(Data()))
            }.eraseToAnyPublisher()
        }))
        
        let scheduler = DispatchQueue.test
        
        let systemEnvironment = SystemEnvironment(environment: lastFmEnvironment, mainQueue: scheduler.eraseToAnyScheduler(), date: { date }, settings: MockSettings())
        
        let store = TestStore(initialState: LastFmTimerState(),
                              reducer: lastFmTimerReducer,
                              environment: systemEnvironment)
        
        store.send(.start) { state in
            state.isTimerActive = true
        }
        
        scheduler.advance(by: 2)
        store.receive(.timerTicked) { state in
            state.secondsElapsed = 1
        }
        
        store.receive(.timerTicked) { state in
            state.secondsElapsed = 2
        }
        
        store.send(.pause) { state in
            state.secondsElapsed = 2
            state.isTimerActive = false
        }
        
        scheduler.advance(by: 2)
        
        store.send(.start) { state in
            state.secondsElapsed = 2
            state.isTimerActive = true
        }
        
        scheduler.advance(by: 1)
        
        store.receive(.timerTicked) { state in
            state.secondsElapsed = 3
        }
        
        store.send(.invalidate) { state in
            state.isTimerActive = false
            state.secondsElapsed = 0
        }
        
    }
}
