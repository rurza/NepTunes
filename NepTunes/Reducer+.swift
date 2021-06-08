//
//  Reducer+.swift
//  NepTunes
//
//  Created by Adam Różyński on 07/06/2021.
//

import ComposableArchitecture

extension Reducer {
    static func strict(_ reducer: @escaping (inout State, Action) -> (Environment) -> Effect<Action, Never>)
    -> Reducer {
        Self { state, action, environment in
            reducer(&state, action)(environment)
        }
    }
}
