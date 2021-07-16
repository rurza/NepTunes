//
//  LastFmEnvironment.swift
//  NepTunes
//
//  Created by Adam Różyński on 31/05/2021.
//

import Foundation

public struct LastFmEnvironment {
    
    var lastFmClient: LastFmUserClient
    var scrobblerClient: ScrobblerClient
    
    public static let live: Self = Self(lastFmClient: .live, scrobblerClient: .live)

}
