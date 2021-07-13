//
//  ScrobblerTimerAction.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/07/2021.
//

import Foundation

enum ScrobblerTimerAction: Equatable {
    case invalidate
    case start(fireInterval: TimeInterval)
    case timerTicked
    case toggle
}

