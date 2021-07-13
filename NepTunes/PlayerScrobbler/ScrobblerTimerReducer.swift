//
//  ScrobblerTimerReducer.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/07/2021.
//

import Foundation
import ComposableArchitecture

let scrobblerTimerReducer = Reducer<ScrobblerTimerState, ScrobblerTimerAction, SystemEnvironment<VoidEnvironment>> { state, action, environment in
    
    struct TimerId: Hashable { }
    
    switch action {
    case .invalidate:
        state.fireInterval = 0
        state.startDate = nil
        return .cancel(id: TimerId())
    case .timerTicked:
        return Effect(value: .invalidate)
    case let .start(interval):
        guard state.startDate == nil else { return .none }
        state.startDate = environment.date()
        state.fireInterval = interval
        return Effect
            .timer(id: TimerId(),
                   every: .seconds(interval),
                   tolerance: .zero,
                   on: environment.runLoop)
            .map { _ in .timerTicked }
    case .toggle:
        if let startDate = state.startDate {
            let difference = environment.date().timeIntervalSince(startDate)
            state.fireInterval -= difference
            state.startDate = nil
            return .cancel(id: TimerId())
        } else if state.fireInterval > 0 {
            return Effect(value: .start(fireInterval: state.fireInterval))
        } else {
            return .none
        }
    }
}
.debug("⏰")
