//
//  MockSettings.swift
//  NepTunesTests
//
//  Created by Adam Różyński on 26/06/2021.
//


class MockSettings: SettingsProvider {

    var session: String? = nil
    
    var username: String? = nil
    
    var scrobblePercentage: UInt = 50
    
    var showCover: Bool = true
    
    var onboardingIsDone: Bool = true
    
}
