//
//  LastFmEnvironment.swift
//  NepTunes
//
//  Created by Adam Różyński on 31/05/2021.
//

import Foundation
import ComposableArchitecture
import Cocoa
import Combine

public struct LastFmEnvironment {
    
    var lastFmClient: LastFmUserClient
    var scrobblerClient: ScrobblerClient
    var signUp: (URL) -> Effect<Void, Never>
    
    public static let live: Self = Self(lastFmClient: .live, scrobblerClient: .live, signUp: signUpEffect)

}

let signUpEffect: (URL) -> Effect<Void, Never> = { url in
    NSWorkspace.shared.open(url)
    return Effect(value: ())
}
