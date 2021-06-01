//
//  PlayerEnvironment.swift
//  NepTunes
//
//  Created by Adam Różyński on 01/06/2021.
//

import Foundation
import ComposableArchitecture

struct PlayerEnvironment {
    var newPlayerLaunched: Effect<PlayerType, Never>
    var playerQuitEffect: Effect<PlayerType, Never>
}
