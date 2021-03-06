//
//  ScrobblerTimerState.swift
//  NepTunes
//
//  Created by Adam Różyński on 13/07/2021.
//

import Foundation

public struct ScrobblerTimerState: Equatable {

    public var fireInterval: TimeInterval = 0
    
    // when the timer last started
    // for exmaple it starts with interval 100s
    // the startDate will be set to current date and if the timer will be paused
    // we will calculate the difference to update the fireInterval
    public var startDate: Date?
    
    public init() { }
    
}

