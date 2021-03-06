//
//  Settings.swift
//  NepTunes
//
//  Created by Adam Różyński on 08/06/2021.
//

import Foundation
import SwiftUI

public protocol SettingsProvider: AnyObject {
    var session: String? { get set }
    var username: String? { get set }
    var scrobblePercentage: UInt { get set }
    var showCover: Bool { get set }
    var onboardingIsDone: Bool { get set }
}

public class Settings: SettingsProvider {
    /// in the version of the app the key was stored in 'pl.micropixels.neptunes.sessionKey'
//    @UserDefault(key: "lastFmSession", defaultValue: nil) public var session: String?
    
    @AppStorage("lastFmSession") public var session: String?
    
    /// in the version of the app the key was stored in 'pl.micropixels.neptunes.usernameKey'
    @AppStorage("lastFmUser") public var username: String?
    
    @UserDefault(key: "scrobblePercentage", defaultValue: 50) public var scrobblePercentage: UInt
    
    @UserDefault(key: "showCover", defaultValue: true) public var showCover: Bool
    
    @UserDefault(key: "onboardingIsDone", defaultValue: false) public var onboardingIsDone: Bool
    
}
