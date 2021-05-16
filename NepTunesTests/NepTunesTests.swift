//
//  NepTunesTests.swift
//  NepTunesTests
//
//  Created by Adam Różyński on 28/04/2021.
//

import XCTest
import ComposableArchitecture
@testable import NepTunes

class NepTunesTests: XCTestCase {

    let testStore = TestStore(initialState: AppState(),
                              reducer: appReducer,
                              environment: AppEnvironment())

}
