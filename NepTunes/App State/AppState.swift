//
//  AppState.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/05/2021.
//

import Foundation

struct AppState: Equatable {

    var settings = Settings()
    var player = PlayerState()
    
    var playerState: SharedState<PlayerState> {
        get {
            return SharedState<PlayerState>(settings: self.settings, state: self.player)
        }
        set {
            self.settings = newValue.settings
            self.player = newValue.state
        }
    }
    
}
