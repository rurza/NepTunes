//
//  LastFmEnvironment.swift
//  NepTunes
//
//  Created by Adam Różyński on 31/05/2021.
//

import Foundation

public struct LastFmEnvironment {
    
    public var lastFmClient: LastFmClient
    
    public init(lastFmClient: LastFmClient) {
        self.lastFmClient = lastFmClient
    }

}
