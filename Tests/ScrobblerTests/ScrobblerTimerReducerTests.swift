//
//  ScrobblerTimerReducerTests.swift
//  NepTunesTests
//
//  Created by Adam Różyński on 01/07/2021.
//

@testable import Scrobbler
@testable import Shared
import XCTest
import ComposableArchitecture
import Combine

class ScrobblerTimerReducerTests: XCTestCase {
    
    func testReducer() throws {
        var date = Date(timeIntervalSince1970: 1624736850)
        
        let runLoop = RunLoop.test
        
        let systemEnvironment = SystemEnvironment(localEnvironment: VoidEnvironment(),
                                                  mainQueue: DispatchQueue.test.eraseToAnyScheduler(),
                                                  runLoop: runLoop.eraseToAnyScheduler(),
                                                  date: { date }, settings: MockSettings())
        
        let store = TestStore(initialState: ScrobblerTimerState(),
                              reducer: scrobblerTimerReducer,
                              environment: systemEnvironment)
        
        let fireInterval: TimeInterval = 5
        store.send(.start(fireInterval: fireInterval)) { state in
            state.fireInterval = fireInterval
            state.startDate = date
        }
        
        date += 2

        store.send(.toggle) { state in
            state.fireInterval = 3
            state.startDate = nil
        }
        
        date += 5
        
        store.send(.toggle) { state in
            state.fireInterval = 3
        }
        
        store.receive(.start(fireInterval: 3)) { state in
            state.startDate = date
        }
        
        runLoop.advance(by: 3)
        
        store.receive(.timerTicked)
        store.receive(.invalidate) { state in
            state.fireInterval = 0
            state.startDate = nil
        }
        
    }
}
