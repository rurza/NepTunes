//
//  SharedState.swift
//  NepTunes
//
//  Created by Adam Różyński on 08/06/2021.
//

import Foundation

import Foundation
import Combine
import ComposableArchitecture

@dynamicMemberLookup
struct SharedState<State: Equatable>: Equatable {
    var settings: Settings
    var state: State
    
    subscript<Dependency>(
        dynamicMember keyPath: WritableKeyPath<State, Dependency>
    ) -> Dependency {
        get { self.state[keyPath: keyPath] }
        set { self.state[keyPath: keyPath] = newValue }
    }
    
    /// Transforms the underlying wrapped state.
    func map<NewState>(_ transform: @escaping (State) -> NewState) -> SharedState<NewState> {
        .init(
            settings: self.settings,
            state: transform(self.state)
        )
    }
}
