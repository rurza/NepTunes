//
//  Settings.swift
//  NepTunes
//
//  Created by Adam Różyński on 08/06/2021.
//

import Foundation

public protocol SettingsProvider: AnyObject {
    var session: String? { get set }
    var username: String? { get set }
    var scrobblePercentage: UInt { get set }
    var showCover: Bool { get set }
}

public class Settings: SettingsProvider {
    /// in the version of the app the key was stored in 'pl.micropixels.neptunes.sessionKey'
    @UserDefault(key: "lastFmSession", defaultValue: nil) public var session: String?
    
    /// in the version of the app the key was stored in 'pl.micropixels.neptunes.usernameKey'
    @UserDefault(key: "lastFmUser", defaultValue: nil) public var username: String?
    
    @UserDefault(key: "scrobblePercentage", defaultValue: 50) public var scrobblePercentage: UInt
    
    @UserDefault(key: "showCover", defaultValue: true) public var showCover: Bool
    
}
