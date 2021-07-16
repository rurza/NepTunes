//
//  Store.swift
//  NepTunes
//
//  Created by Adam Różyński on 16/07/2021.
//

import ComposableArchitecture
import AppCore
import Shared

let store = Store(initialState: AppState(), reducer: appReducer, environment: SystemEnvironment.live(environment: AppEnvironment.live))
