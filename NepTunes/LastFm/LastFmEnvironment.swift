//
//  LastFmEnvironment.swift
//  NepTunes
//
//  Created by Adam Różyński on 31/05/2021.
//

import Foundation
import LastFmKit
import ComposableArchitecture

struct LastFmEnvironment {
    var lastFmClient: LastFmClient
}

let scrobbleTimer: (Track, TimeInterval) -> Effect<Track, Never> = { track, interval in
    Timer.publish(every: interval,
                  on: .main,
                  in: .common,
                  options: nil)
        .autoconnect()
        .map { _ in track }
        .eraseToEffect()
}
